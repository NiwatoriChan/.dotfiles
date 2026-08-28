import Quickshell
import QtQuick
import "../../services" as QsServices

Scope {
    id: root
    
    property var pywal: QsServices.Pywal
    
    VolumeOSD {
        pywal: root.pywal
    }
    
    BrightnessOSD {
        pywal: root.pywal
    }
}

