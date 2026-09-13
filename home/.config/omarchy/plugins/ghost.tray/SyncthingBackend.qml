pragma Singleton

import QtQuick
import "../io.github.ilyazar.syncthing" as Syncthing

QtObject {
  id: root
  property int consumers: 0
  property var service: null
  property Component factory: Component { Syncthing.Service {} }

  function acquire() {
    if (!service) service = factory.createObject(root)
    consumers++
  }

  function release() {
    consumers--
    if (consumers === 0 && service) {
      service.destroy()
      service = null
    }
  }
}
