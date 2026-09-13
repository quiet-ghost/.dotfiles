import QtQuick
import "../io.github.ilyazar.syncthing" as Syncthing
import "." as Backend

// The tray owns the backend while hosted; the upstream panel stays unmodified.
Syncthing.Panel {
  readonly property var syncthing: Backend.SyncthingBackend.service
  Component.onCompleted: Backend.SyncthingBackend.acquire()
  Component.onDestruction: Backend.SyncthingBackend.release()
}
