#!/usr/bin/env python3

import json
import os
import shlex
import socket
import subprocess
import sys
import time
from pathlib import Path


RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
SOCKET_PATH = RUNTIME_DIR / "omarchy-youtube-music.sock"
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state")) / "omarchy" / "youtube-music"
AUTH_PATH = STATE_DIR / "browser.json"
VENV_PYTHON = Path.home() / ".local" / "share" / "omarchy-youtube-music" / "venv" / "bin" / "python"


def output(value: object) -> None:
    print(json.dumps(value, ensure_ascii=True), flush=True)


def fail(message: str) -> None:
    output({"ok": False, "error": message})
    raise SystemExit(1)


def ytmusic_client():
    try:
        from ytmusicapi import YTMusic
    except ImportError:
        fail("The YouTube Music API runtime is missing. Reinstall the local plugin runtime.")
    if not AUTH_PATH.is_file():
        fail("YouTube Music is not connected")
    return YTMusic(str(AUTH_PATH))


def thumbnail(item: dict[str, object]) -> str:
    thumbnails = item.get("thumbnails") or []
    if isinstance(thumbnails, list) and thumbnails:
        last = thumbnails[-1]
        if isinstance(last, dict):
            return str(last.get("url") or "")
    return ""


def artist_text(item: dict[str, object]) -> str:
    artists = item.get("artists") or []
    if isinstance(artists, list):
        names = [str(value.get("name") or "") for value in artists if isinstance(value, dict)]
        return ", ".join(name for name in names if name)
    author = item.get("author")
    if isinstance(author, list):
        return ", ".join(str(value.get("name") or "") for value in author if isinstance(value, dict))
    return str(author or item.get("subtitle") or "")


def normalize_item(item: object) -> dict[str, object] | None:
    if not isinstance(item, dict):
        return None
    video_id = str(item.get("videoId") or item.get("id") or "")
    playlist_id = str(item.get("playlistId") or "")
    browse_id = str(item.get("browseId") or "")
    result_type = str(item.get("resultType") or item.get("type") or "")
    if video_id:
        return {
            "kind": "track",
            "id": video_id,
            "title": str(item.get("title") or "Unknown track"),
            "artist": artist_text(item),
            "duration": int(item.get("duration_seconds") or item.get("durationSeconds") or 0),
            "thumbnail": thumbnail(item),
            "url": f"https://music.youtube.com/watch?v={video_id}",
        }
    context_id = playlist_id or browse_id
    if not context_id:
        return None
    kind = "playlist" if playlist_id or result_type == "playlist" else (result_type or "collection")
    return {
        "kind": kind,
        "id": context_id,
        "playlistId": playlist_id,
        "browseId": browse_id,
        "title": str(item.get("title") or "YouTube Music"),
        "artist": artist_text(item),
        "thumbnail": thumbnail(item),
    }


def normalize_auth_input(value: str) -> str:
    text = value.strip()
    if text.startswith("/") or text.startswith("https://music.youtube.com/"):
        fail("That is only the request URL. In Developer Tools, right-click the request and choose Copy > Copy as cURL.")
    if not text.startswith("curl "):
        return text

    try:
        parts = shlex.split(text)
    except ValueError:
        fail("The copied cURL request could not be parsed. Copy it again without editing it.")

    headers: list[str] = []
    index = 1
    while index < len(parts):
        part = parts[index]
        if part in {"-H", "--header"} and index + 1 < len(parts):
            headers.append(parts[index + 1])
            index += 2
            continue
        if part in {"-b", "--cookie"} and index + 1 < len(parts):
            headers.append(f"cookie: {parts[index + 1]}")
            index += 2
            continue
        index += 1
    return "\n".join(headers)


def auth_setup() -> None:
    try:
        request = json.loads(sys.stdin.readline())
        headers = normalize_auth_input(str(request.get("headers") or ""))
    except (json.JSONDecodeError, AttributeError):
        fail("The copied request headers could not be read")
    if "cookie:" not in headers.lower() and '"cookie"' not in headers.lower():
        fail("The copied request is missing its Cookie header. Use Copy > Copy as cURL on the browse request.")

    try:
        import ytmusicapi

        STATE_DIR.mkdir(parents=True, exist_ok=True, mode=0o700)
        temporary = STATE_DIR / "browser.json.tmp"
        ytmusicapi.setup(filepath=str(temporary), headers_raw=headers)
        os.chmod(temporary, 0o600)
        from ytmusicapi import YTMusic

        account = YTMusic(str(temporary)).get_account_info()
        if not account:
            temporary.unlink(missing_ok=True)
            fail("Google accepted the session, but no YouTube Music account was found")
        temporary.replace(AUTH_PATH)
        os.chmod(AUTH_PATH, 0o600)
        output({"ok": True, "authenticated": True, "account": account})
    except SystemExit:
        raise
    except Exception as error:
        (STATE_DIR / "browser.json.tmp").unlink(missing_ok=True)
        fail(f"YouTube Music login failed: {error}")


def auth_status() -> None:
    if not AUTH_PATH.is_file():
        output({"ok": True, "authenticated": False})
        return
    try:
        account = ytmusic_client().get_account_info()
        output({"ok": True, "authenticated": bool(account), "account": account or {}})
    except Exception as error:
        output({"ok": True, "authenticated": False, "error": f"Saved login expired: {error}"})


def auth_logout() -> None:
    AUTH_PATH.unlink(missing_ok=True)
    output({"ok": True, "authenticated": False})


def home() -> None:
    try:
        sections = []
        for section in ytmusic_client().get_home(limit=10):
            items = []
            for raw in section.get("contents") or []:
                item = normalize_item(raw)
                if item:
                    items.append(item)
            if items:
                sections.append({"title": str(section.get("title") or "For you"), "items": items})
        output({"ok": True, "sections": sections})
    except Exception as error:
        fail(f"Your YouTube Music home could not be loaded: {error}")


def library(kind: str) -> None:
    client = ytmusic_client()
    methods = {
        "playlists": lambda: client.get_library_playlists(limit=100),
        "songs": lambda: client.get_library_songs(limit=100),
        "liked": lambda: client.get_liked_songs(limit=100),
        "albums": lambda: client.get_library_albums(limit=100),
        "artists": lambda: client.get_library_artists(limit=100),
        "history": lambda: client.get_history(),
    }
    if kind not in methods:
        fail(f"Unknown library view: {kind}")
    try:
        raw = methods[kind]()
        if isinstance(raw, dict):
            raw = raw.get("tracks") or raw.get("items") or []
        items = [item for value in raw or [] if (item := normalize_item(value))]
        output({"ok": True, "items": items})
    except Exception as error:
        fail(f"Your YouTube Music {kind} could not be loaded: {error}")


def playlist(playlist_id: str) -> None:
    try:
        value = ytmusic_client().get_playlist(playlist_id, limit=200)
        items = [item for raw in value.get("tracks") or [] if (item := normalize_item(raw))]
        output({"ok": True, "title": str(value.get("title") or "Playlist"), "items": items})
    except Exception as error:
        fail(f"This YouTube Music playlist could not be loaded: {error}")


def context(kind: str, item_id: str, playlist_id: str, title: str, mode: str) -> None:
    client = ytmusic_client()
    normalized_kind = kind.lower()
    try:
        tracks: list[object] = []
        source_playlist_id = playlist_id

        if normalized_kind == "playlist" or playlist_id:
            value = client.get_playlist(playlist_id or item_id, limit=200)
            title = str(value.get("title") or title or "Playlist")
            tracks = value.get("tracks") or []
            source_playlist_id = playlist_id or item_id
        elif normalized_kind in {"album", "single", "ep"} or item_id.startswith("MPRE"):
            value = client.get_album(item_id)
            title = str(value.get("title") or title or "Album")
            tracks = value.get("tracks") or []
            source_playlist_id = str(value.get("audioPlaylistId") or "")
        elif item_id.startswith("UC") or normalized_kind in {"artist", "collection"}:
            value = client.get_artist(item_id)
            title = str(value.get("name") or title or "Artist")
            song_group = value.get("songs") or value.get("latestSongs") or {}
            tracks = song_group.get("results") or []
            if not tracks and song_group.get("browseId"):
                songs = client.get_playlist(str(song_group["browseId"]), limit=100)
                tracks = songs.get("tracks") or []
        else:
            fail("This Home collection type is not supported yet")

        if mode == "shuffle" and source_playlist_id:
            value = client.get_watch_playlist(playlistId=source_playlist_id, limit=100, shuffle=True)
            tracks = value.get("tracks") or tracks
        elif mode == "radio":
            first = normalize_item(tracks[0]) if tracks else None
            if first and first.get("id"):
                value = client.get_watch_playlist(videoId=str(first["id"]), limit=100, radio=True)
                tracks = value.get("tracks") or tracks

        items = [item for raw in tracks if (item := normalize_item(raw))]
        if not items:
            fail("YouTube Music did not return any playable tracks for this collection")
        output({"ok": True, "title": title, "items": items, "autoplay": mode != "open"})
    except SystemExit:
        raise
    except Exception as error:
        fail(f"This YouTube Music collection could not be loaded: {error}")


def search(query: str) -> None:
    if not query.strip():
        output({"ok": True, "items": []})
        return

    command = [
        "yt-dlp",
        "--flat-playlist",
        "--dump-single-json",
        "--no-warnings",
        "--playlist-end",
        "20",
        f"ytsearch20:{query}",
    ]
    result = subprocess.run(command, capture_output=True, text=True, timeout=45)
    if result.returncode != 0:
        detail = result.stderr.strip().splitlines()
        fail(detail[-1] if detail else "YouTube Music search failed")

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError:
        fail("YouTube Music returned an unreadable search response")

    items = []
    for entry in payload.get("entries") or []:
        video_id = str(entry.get("id") or "")
        if not video_id:
            continue
        thumbnails = entry.get("thumbnails") or []
        thumbnail = str(entry.get("thumbnail") or "")
        if thumbnails:
            thumbnail = str(thumbnails[-1].get("url") or thumbnail)
        items.append(
            {
                "id": video_id,
                "title": str(entry.get("title") or "Unknown track"),
                "artist": str(entry.get("channel") or entry.get("uploader") or ""),
                "duration": int(entry.get("duration") or 0),
                "thumbnail": thumbnail,
                "url": f"https://music.youtube.com/watch?v={video_id}",
            }
        )
    output({"ok": True, "items": items})


def send(command: list[object], retries: int = 0) -> dict[str, object]:
    for attempt in range(retries + 1):
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
                client.settimeout(3)
                client.connect(str(SOCKET_PATH))
                client.sendall((json.dumps({"command": command}) + "\n").encode())
                response = b""
                while b"\n" not in response:
                    chunk = client.recv(65536)
                    if not chunk:
                        break
                    response += chunk
                return json.loads(response.decode().splitlines()[0])
        except (FileNotFoundError, ConnectionRefusedError, TimeoutError, json.JSONDecodeError):
            if attempt >= retries:
                raise
            time.sleep(0.15)
    raise RuntimeError("mpv IPC did not respond")


def ensure_player() -> None:
    try:
        send(["get_property", "idle-active"])
        return
    except (FileNotFoundError, ConnectionRefusedError, TimeoutError, json.JSONDecodeError):
        SOCKET_PATH.unlink(missing_ok=True)

    subprocess.Popen(
        [
            "mpv",
            "--no-video",
            "--idle=yes",
            "--force-window=no",
            "--no-terminal",
            f"--input-ipc-server={SOCKET_PATH}",
            "--ytdl-format=bestaudio/best",
        ],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    send(["get_property", "idle-active"], retries=20)


def command(name: str, args: list[str]) -> None:
    if name == "play":
        if len(args) < 2:
            fail("play requires a URL and title")
        ensure_player()
        response = send(["loadfile", args[0], "replace"])
        if response.get("error") != "success":
            fail("mpv could not start this track")
        output({"ok": True})
        return

    try:
        if name == "state":
            properties = ["idle-active", "pause", "time-pos", "duration", "media-title"]
            values: dict[str, object] = {}
            for prop in properties:
                response = send(["get_property", prop])
                values[prop] = response.get("data") if response.get("error") == "success" else None
            idle = values["idle-active"] is not False
            output(
                {
                    "ok": True,
                    "running": not idle,
                    "playing": not idle and values["pause"] is not True,
                    "position": float(values["time-pos"] or 0),
                    "duration": float(values["duration"] or 0),
                    "title": str(values["media-title"] or ""),
                }
            )
            if idle:
                send(["quit"])
                SOCKET_PATH.unlink(missing_ok=True)
        elif name == "toggle":
            ensure_player()
            send(["cycle", "pause"])
            output({"ok": True})
        elif name == "seek":
            ensure_player()
            send(["set_property", "time-pos", max(0, float(args[0]))])
            output({"ok": True})
        elif name == "stop":
            send(["quit"])
            SOCKET_PATH.unlink(missing_ok=True)
            output({"ok": True})
        else:
            fail(f"Unknown command: {name}")
    except (FileNotFoundError, ConnectionRefusedError, TimeoutError, json.JSONDecodeError):
        if name == "state":
            output({"ok": True, "running": False, "playing": False, "position": 0, "duration": 0})
        else:
            fail("The local music player is not available")


def main() -> None:
    if len(sys.argv) < 2:
        fail("Expected search or player command")
    if sys.argv[1] == "auth-setup":
        auth_setup()
    elif sys.argv[1] == "auth-status":
        auth_status()
    elif sys.argv[1] == "auth-logout":
        auth_logout()
    elif sys.argv[1] == "home":
        home()
    elif sys.argv[1] == "library":
        library(sys.argv[2] if len(sys.argv) > 2 else "songs")
    elif sys.argv[1] == "playlist":
        playlist(sys.argv[2] if len(sys.argv) > 2 else "")
    elif sys.argv[1] == "context":
        context(
            sys.argv[2] if len(sys.argv) > 2 else "",
            sys.argv[3] if len(sys.argv) > 3 else "",
            sys.argv[4] if len(sys.argv) > 4 else "",
            sys.argv[5] if len(sys.argv) > 5 else "",
            sys.argv[6] if len(sys.argv) > 6 else "open",
        )
    elif sys.argv[1] == "search":
        search(sys.argv[2] if len(sys.argv) > 2 else "")
    else:
        command(sys.argv[1], sys.argv[2:])


if __name__ == "__main__":
    main()
