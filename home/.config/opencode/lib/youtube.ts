import type { ToolEditor } from "@opencode-ai/plugin/promise/tool";
import { z } from "zod";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";

const DEFAULT_LANGUAGE = "en";
const DEFAULT_CHUNK_SIZE = 36_000;
const MAX_CHUNK_SIZE = 45_000;
const VIDEO_ID_PATTERN = /^[A-Za-z0-9_-]{11}$/;
const ALLOWED_HOSTS = new Set([
  "youtube.com",
  "www.youtube.com",
  "m.youtube.com",
  "music.youtube.com",
  "youtu.be",
]);

type VideoRef = {
  videoId: string;
  canonicalUrl: string;
};

type CaptionSource = "manual" | "automatic" | "yt-dlp-file";

type CaptionChoice = {
  url: string;
  language: string;
  source: CaptionSource;
};

type VideoMetadata = {
  videoId: string;
  canonicalUrl: string;
  title: string;
  safeTitle: string;
  channel: string;
  channelId: string;
  uploader: string;
  uploadDate: string;
  publishDate: string;
  durationSeconds: number | undefined;
  duration: string;
  description: string;
  tags: string[];
  viewCount: number | undefined;
  likeCount: number | undefined;
  metadataSource: "yt-dlp" | "google-api" | "yt-dlp+google-api";
};

type CachedVideo = {
  metadata: VideoMetadata;
  transcript: string;
  transcriptLanguage: string;
  transcriptSource: CaptionSource;
  warnings: string[];
};

type CaptionData = {
  transcript: string;
  language: string;
  source: CaptionSource;
};

const cache = new Map<string, CachedVideo>();

function asRecord(value: unknown): Record<string, unknown> | undefined {
  const parsed = z.record(z.string(), z.unknown()).safeParse(value);
  return parsed.success ? parsed.data : undefined;
}

function getString(record: Record<string, unknown>, key: string): string {
  const value = record[key];
  return typeof value === "string" ? value : "";
}

function getNumber(
  record: Record<string, unknown>,
  key: string,
): number | undefined {
  const value = record[key];
  return typeof value === "number" && Number.isFinite(value)
    ? value
    : undefined;
}

function getStringArray(
  record: Record<string, unknown>,
  key: string,
): string[] {
  const value = record[key];
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

function normalizeInputUrl(rawUrl: string): URL {
  const trimmed = rawUrl.trim();
  if (!trimmed) throw new Error("YouTube URL is required.");
  const withProtocol = /^[a-z][a-z0-9+.-]*:/i.test(trimmed)
    ? trimmed
    : `https://${trimmed}`;
  return new URL(withProtocol);
}

function parseYouTubeUrl(rawUrl: string): VideoRef {
  const url = normalizeInputUrl(rawUrl);
  const host = url.hostname.toLowerCase();
  if (!ALLOWED_HOSTS.has(host)) {
    throw new Error(
      `Unsupported YouTube host: ${url.hostname}. Use youtube.com or youtu.be video links.`,
    );
  }

  let videoId = "";
  if (host === "youtu.be") {
    const [firstSegment] = url.pathname.split("/").filter(Boolean);
    videoId = firstSegment ?? "";
  } else {
    videoId = url.searchParams.get("v") ?? "";
    const segments = url.pathname.split("/").filter(Boolean);
    const [first, second] = segments;
    if (!videoId && ["shorts", "live", "embed", "v"].includes(first ?? "")) {
      videoId = second ?? "";
    }
  }

  if (!videoId && url.searchParams.has("list")) {
    throw new Error(
      "Playlist-only URLs are not supported yet. Paste a video URL.",
    );
  }

  if (!VIDEO_ID_PATTERN.test(videoId)) {
    throw new Error("Could not extract a valid YouTube video ID from the URL.");
  }

  return {
    videoId,
    canonicalUrl: `https://www.youtube.com/watch?v=${videoId}`,
  };
}

function normalizeLanguage(language: string | undefined): string {
  const value = language?.trim() || DEFAULT_LANGUAGE;
  if (!/^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})?$/.test(value)) {
    throw new Error(
      `Invalid transcript language: ${value}. Use a code like en, es, or pt-BR.`,
    );
  }
  return value;
}

function languageCandidates(
  requestedLanguage: string,
  availableLanguages: string[],
): string[] {
  const requested = requestedLanguage.toLowerCase();
  const base = requested.split("-")[0] ?? requested;
  const matches = availableLanguages.filter((language) => {
    const normalized = language.toLowerCase();
    return (
      normalized === requested ||
      normalized === base ||
      normalized.startsWith(`${base}-`) ||
      normalized.startsWith(`${base}.`)
    );
  });
  return [...new Set([...matches, ...availableLanguages])];
}

function formatUploadDate(value: string): string {
  if (/^\d{8}$/.test(value)) {
    return `${value.slice(0, 4)}-${value.slice(4, 6)}-${value.slice(6, 8)}`;
  }
  return value;
}

function formatDuration(seconds: number | undefined): string {
  if (seconds === undefined) return "";
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const remainingSeconds = Math.floor(seconds % 60);
  const parts =
    hours > 0
      ? [hours, minutes, remainingSeconds]
      : [minutes, remainingSeconds];
  return parts.map((part) => part.toString().padStart(2, "0")).join(":");
}

function safeTitle(title: string, fallback: string): string {
  const normalized = title
    .replace(/[<>:"/\\|?*\x00-\x1F]/g, "")
    .replace(/\s+/g, " ")
    .trim();
  const value = normalized || fallback;
  return value.length > 90 ? value.slice(0, 90).trim() : value;
}

function decodeHtmlEntities(value: string): string {
  const entities: Record<string, string> = {
    "&amp;": "&",
    "&lt;": "<",
    "&gt;": ">",
    "&quot;": '"',
    "&#39;": "'",
  };
  return value.replace(
    /&(amp|lt|gt|quot|#39);/g,
    (match) => entities[match] ?? match,
  );
}

function stripVttTags(value: string): string {
  return decodeHtmlEntities(value.replace(/<[^>]*>/g, ""))
    .replace(/\s+/g, " ")
    .trim();
}

function normalizeTimestamp(value: string): string {
  const [withoutMillis] = value.trim().split(".");
  return withoutMillis ?? value.trim();
}

function parseVtt(vtt: string, includeTimestamps: boolean): string {
  const lines = vtt.split(/\r?\n/);
  const output: string[] = [];
  const seenPlain = new Set<string>();
  let currentTimestamp = "";

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (
      !line ||
      line === "WEBVTT" ||
      line.startsWith("NOTE") ||
      line.startsWith("STYLE") ||
      line.startsWith("Kind:") ||
      line.startsWith("Language:") ||
      /^\d+$/.test(line)
    ) {
      continue;
    }

    if (line.includes("-->")) {
      const [start] = line.split("-->");
      currentTimestamp = normalizeTimestamp(start ?? "");
      continue;
    }

    const clean = stripVttTags(line);
    if (!clean) continue;

    if (includeTimestamps && currentTimestamp) {
      const timestamped = `[${currentTimestamp}] ${clean}`;
      output.push(timestamped);
      continue;
    }

    if (seenPlain.has(clean)) continue;
    seenPlain.add(clean);
    output.push(clean);
  }

  return output.join(includeTimestamps ? "\n" : " ").trim();
}

function captionMap(
  metadata: Record<string, unknown>,
  key: "subtitles" | "automatic_captions",
): Record<string, unknown> {
  return asRecord(metadata[key]) ?? {};
}

function chooseCaptionFromMap(
  captions: Record<string, unknown>,
  requestedLanguage: string,
  source: CaptionSource,
): CaptionChoice | undefined {
  const languages = Object.keys(captions);
  for (const language of languageCandidates(requestedLanguage, languages)) {
    const entries = captions[language];
    if (!Array.isArray(entries)) continue;
    for (const rawEntry of entries) {
      const entry = asRecord(rawEntry);
      if (!entry) continue;
      const url = getString(entry, "url");
      const ext = getString(entry, "ext");
      if (!url || (ext && ext !== "vtt")) continue;
      return { url, language, source };
    }
  }
}

function chooseCaption(
  metadata: Record<string, unknown>,
  requestedLanguage: string,
): CaptionChoice | undefined {
  const subtitles = captionMap(metadata, "subtitles");
  const manual = chooseCaptionFromMap(subtitles, requestedLanguage, "manual");
  if (manual) return manual;

  const automaticCaptions = captionMap(metadata, "automatic_captions");
  return chooseCaptionFromMap(
    automaticCaptions,
    requestedLanguage,
    "automatic",
  );
}

async function runYtDlp(args: string[]): Promise<string> {
  const command = ["yt-dlp", ...args];
  const result = await Bun.$`${command}`.nothrow().quiet();
  if (result.exitCode !== 0) {
    const stderr = result.stderr.toString().trim();
    throw new Error(stderr || "yt-dlp failed without an error message.");
  }
  return result.stdout.toString();
}

function lastJsonLine(output: string): string {
  const lines = output.split(/\r?\n/).map((line) => line.trim());
  for (let index = lines.length - 1; index >= 0; index -= 1) {
    const line = lines[index];
    if (line?.startsWith("{")) return line;
  }
  throw new Error("yt-dlp did not return video metadata JSON.");
}

async function fetchYtDlpMetadata(
  canonicalUrl: string,
): Promise<Record<string, unknown>> {
  const output = await runYtDlp([
    "--dump-json",
    "--skip-download",
    "--no-playlist",
    "--no-warnings",
    canonicalUrl,
  ]);
  const parsed = JSON.parse(lastJsonLine(output));
  const record = asRecord(parsed);
  if (!record)
    throw new Error("yt-dlp returned metadata in an unexpected shape.");
  return record;
}

async function fetchCaptionFromMetadata(
  metadata: Record<string, unknown>,
  language: string,
  includeTimestamps: boolean,
): Promise<CaptionData | undefined> {
  const choice = chooseCaption(metadata, language);
  if (!choice) return;

  const response = await globalThis.fetch(choice.url);
  if (!response.ok) {
    throw new Error(`Caption download failed with HTTP ${response.status}.`);
  }

  const transcript = parseVtt(await response.text(), includeTimestamps);
  if (!transcript) throw new Error("Caption file was empty after parsing.");

  return {
    transcript,
    language: choice.language,
    source: choice.source,
  };
}

function findVttFiles(directory: string): string[] {
  const entries = fs.readdirSync(directory, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...findVttFiles(entryPath));
      continue;
    }
    if (entry.name.toLowerCase().endsWith(".vtt")) files.push(entryPath);
  }
  return files;
}

function chooseVttFile(files: string[], language: string): string {
  const requested = language.toLowerCase();
  const base = requested.split("-")[0] ?? requested;
  const preferred = files.find((file) =>
    file.toLowerCase().includes(`.${requested}.vtt`),
  );
  if (preferred) return preferred;
  const basePreferred = files.find((file) =>
    file.toLowerCase().includes(`.${base}.`),
  );
  if (basePreferred) return basePreferred;
  const [first] = files;
  if (!first) throw new Error("yt-dlp did not create a VTT subtitle file.");
  return first;
}

async function fetchCaptionWithYtDlpFile(
  ref: VideoRef,
  language: string,
  includeTimestamps: boolean,
): Promise<CaptionData> {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "opencode-youtube-"));
  try {
    const outputPath = path.join(tempDir, "%(id)s.%(ext)s");
    const baseLanguage = language.split("-")[0] ?? language;
    const subLanguages = `${language},${baseLanguage}.*,${baseLanguage}`;
    await runYtDlp([
      "--write-subs",
      "--write-auto-subs",
      "--skip-download",
      "--sub-format",
      "vtt",
      "--sub-langs",
      subLanguages,
      "--no-playlist",
      "-o",
      outputPath,
      ref.canonicalUrl,
    ]);
    const chosenFile = chooseVttFile(findVttFiles(tempDir), language);
    const transcript = parseVtt(
      fs.readFileSync(chosenFile, "utf8"),
      includeTimestamps,
    );
    if (!transcript)
      throw new Error("Downloaded caption file was empty after parsing.");
    return {
      transcript,
      language,
      source: "yt-dlp-file",
    };
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
}

function mergeMetadata(
  ref: VideoRef,
  ytdlpMetadata: Record<string, unknown>,
  googleMetadata: Partial<VideoMetadata> | undefined,
): VideoMetadata {
  const title =
    googleMetadata?.title || getString(ytdlpMetadata, "title") || ref.videoId;
  const channel =
    googleMetadata?.channel ||
    getString(ytdlpMetadata, "channel") ||
    getString(ytdlpMetadata, "uploader");
  const uploadDate =
    googleMetadata?.uploadDate ||
    googleMetadata?.publishDate ||
    formatUploadDate(getString(ytdlpMetadata, "upload_date"));
  const durationSeconds =
    googleMetadata?.durationSeconds ?? getNumber(ytdlpMetadata, "duration");
  const hasGoogle = Boolean(googleMetadata);

  return {
    videoId: ref.videoId,
    canonicalUrl: ref.canonicalUrl,
    title,
    safeTitle: safeTitle(title, ref.videoId),
    channel,
    channelId:
      googleMetadata?.channelId || getString(ytdlpMetadata, "channel_id"),
    uploader: googleMetadata?.uploader || getString(ytdlpMetadata, "uploader"),
    uploadDate,
    publishDate: googleMetadata?.publishDate || uploadDate,
    durationSeconds,
    duration: formatDuration(durationSeconds),
    description:
      googleMetadata?.description || getString(ytdlpMetadata, "description"),
    tags: googleMetadata?.tags?.length
      ? googleMetadata.tags
      : getStringArray(ytdlpMetadata, "tags"),
    viewCount:
      googleMetadata?.viewCount ?? getNumber(ytdlpMetadata, "view_count"),
    likeCount:
      googleMetadata?.likeCount ?? getNumber(ytdlpMetadata, "like_count"),
    metadataSource: hasGoogle ? "yt-dlp+google-api" : "yt-dlp",
  };
}

function parseIsoDuration(value: string): number | undefined {
  const match = value.match(/^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);
  if (!match) return;
  const hours = Number.parseInt(match[1] ?? "0", 10);
  const minutes = Number.parseInt(match[2] ?? "0", 10);
  const seconds = Number.parseInt(match[3] ?? "0", 10);
  return hours * 3600 + minutes * 60 + seconds;
}

async function fetchGoogleMetadata(
  videoId: string,
  apiKey: string | undefined,
): Promise<Partial<VideoMetadata> | undefined> {
  if (!apiKey) return;
  const params = new URLSearchParams({
    part: "snippet,contentDetails,statistics",
    id: videoId,
    key: apiKey,
  });
  const response = await globalThis.fetch(
    `https://www.googleapis.com/youtube/v3/videos?${params.toString()}`,
  );
  if (!response.ok) {
    throw new Error(`YouTube Data API returned HTTP ${response.status}.`);
  }
  const body = asRecord(await response.json());
  const items = body && Array.isArray(body.items) ? body.items : [];
  const firstItem = asRecord(items[0]);
  if (!firstItem) return;

  const snippet = asRecord(firstItem.snippet) ?? {};
  const contentDetails = asRecord(firstItem.contentDetails) ?? {};
  const statistics = asRecord(firstItem.statistics) ?? {};
  const durationSeconds = parseIsoDuration(
    getString(contentDetails, "duration"),
  );
  const viewCountValue = getString(statistics, "viewCount");
  const likeCountValue = getString(statistics, "likeCount");
  const publishedAt = getString(snippet, "publishedAt");

  return {
    title: getString(snippet, "title"),
    channel: getString(snippet, "channelTitle"),
    channelId: getString(snippet, "channelId"),
    uploader: getString(snippet, "channelTitle"),
    description: getString(snippet, "description"),
    publishDate: publishedAt,
    uploadDate: publishedAt.slice(0, 10),
    durationSeconds,
    tags: getStringArray(snippet, "tags"),
    viewCount: viewCountValue ? Number.parseInt(viewCountValue, 10) : undefined,
    likeCount: likeCountValue ? Number.parseInt(likeCountValue, 10) : undefined,
    metadataSource: "google-api",
  };
}

async function fetchVideo(
  ref: VideoRef,
  language: string,
  includeTimestamps: boolean,
  includeGoogleMetadata: boolean,
): Promise<CachedVideo> {
  const warnings: string[] = [];
  const ytdlpMetadata = await fetchYtDlpMetadata(ref.canonicalUrl);

  let googleMetadata: Partial<VideoMetadata> | undefined;
  if (includeGoogleMetadata) {
    try {
      googleMetadata = await fetchGoogleMetadata(
        ref.videoId,
        process.env.YOUTUBE_API_KEY,
      );
    } catch (error) {
      warnings.push(
        `Google metadata unavailable; using yt-dlp metadata. Cause: ${error instanceof Error ? error.message : "unknown error"}`,
      );
    }
  }

  let caption: CaptionData | undefined;
  try {
    caption = await fetchCaptionFromMetadata(
      ytdlpMetadata,
      language,
      includeTimestamps,
    );
  } catch (error) {
    warnings.push(
      `Direct caption URL failed; falling back to yt-dlp subtitle download. Cause: ${error instanceof Error ? error.message : "unknown error"}`,
    );
  }

  if (!caption) {
    caption = await fetchCaptionWithYtDlpFile(ref, language, includeTimestamps);
  }

  return {
    metadata: mergeMetadata(ref, ytdlpMetadata, googleMetadata),
    transcript: caption.transcript,
    transcriptLanguage: caption.language,
    transcriptSource: caption.source,
    warnings,
  };
}

function chunkTranscript(transcript: string, chunkSize: number): string[] {
  const chunks: string[] = [];
  for (let start = 0; start < transcript.length; start += chunkSize) {
    chunks.push(transcript.slice(start, start + chunkSize));
  }
  return chunks.length ? chunks : [""];
}

function cacheKey(
  ref: VideoRef,
  language: string,
  timestamps: boolean,
): string {
  return [
    ref.videoId,
    language.toLowerCase(),
    timestamps ? "ts" : "plain",
  ].join(":");
}

export function registerYouTube(editor: ToolEditor): void {
  editor.add({
    name: "youtube_fetch",
    options: { permission: "youtube_fetch" },
    description: `Fetch YouTube video metadata and transcript for note-taking.

Use for youtube.com or youtu.be video URLs. Returns structured JSON with metadata and one transcript chunk. If totalChunks is greater than 1, call again with the same URL and the next chunkIndex until all chunks are processed. Uses yt-dlp for transcripts and optional YOUTUBE_API_KEY for richer metadata.`,
    input: z.object({
      url: z.string().describe("YouTube video URL"),
      language: z
        .string()
        .optional()
        .describe("Preferred transcript language, default en"),
      timestamps: z
        .boolean()
        .optional()
        .describe("Include timestamps in transcript lines, default true"),
      chunkIndex: z
        .number()
        .int()
        .min(0)
        .optional()
        .describe("Transcript chunk index to return, default 0"),
      chunkSize: z
        .number()
        .int()
        .min(5_000)
        .max(MAX_CHUNK_SIZE)
        .optional()
        .describe(`Transcript characters per chunk, max ${MAX_CHUNK_SIZE}`),
      refresh: z
        .boolean()
        .optional()
        .describe("Refetch instead of using the in-process cache"),
      googleMetadata: z
        .boolean()
        .optional()
        .describe(
          "Use YOUTUBE_API_KEY for richer metadata when available, default true",
        ),
    }),
    async execute(args, context) {
      const ref = parseYouTubeUrl(args.url);
      const language = normalizeLanguage(args.language);
      const includeTimestamps = args.timestamps ?? true;
      const includeGoogleMetadata = args.googleMetadata ?? true;
      const chunkSize = args.chunkSize ?? DEFAULT_CHUNK_SIZE;
      const requestedChunk = args.chunkIndex ?? 0;

      const key = cacheKey(ref, language, includeTimestamps);
      let video = cache.get(key);
      if (!video || args.refresh) {
        video = await fetchVideo(
          ref,
          language,
          includeTimestamps,
          includeGoogleMetadata,
        );
        cache.set(key, video);
      }

      await context.progress({
        title: video.metadata.title,
        metadata: {
          videoId: video.metadata.videoId,
          channel: video.metadata.channel,
          transcriptSource: video.transcriptSource,
        },
      });

      const chunks = chunkTranscript(video.transcript, chunkSize);
      const safeChunkIndex = Math.min(requestedChunk, chunks.length - 1);
      const chunk = chunks[safeChunkIndex] ?? "";

      return {
        content: JSON.stringify(
          {
            kind: "youtube-video-notes-source",
            metadata: video.metadata,
            transcript: {
              language: video.transcriptLanguage,
              source: video.transcriptSource,
              includesTimestamps: includeTimestamps,
              totalChars: video.transcript.length,
              chunkChars: chunk.length,
              chunkIndex: safeChunkIndex,
              totalChunks: chunks.length,
              hasMoreChunks: safeChunkIndex + 1 < chunks.length,
              nextChunkIndex:
                safeChunkIndex + 1 < chunks.length
                  ? safeChunkIndex + 1
                  : undefined,
              text: chunk,
            },
            warnings: video.warnings,
            noteDefaults: {
              saveDirectory: "/home/ghost/personal/Notes/Imports/",
              suggestedFilename: `${video.metadata.uploadDate || "undated"} - ${video.metadata.safeTitle}.md`,
            },
          },
          null,
          2,
        ),
        metadata: {
          videoId: video.metadata.videoId,
          title: video.metadata.title,
          channel: video.metadata.channel,
          chunkIndex: safeChunkIndex,
          totalChunks: chunks.length,
        },
      };
    },
  });
}
