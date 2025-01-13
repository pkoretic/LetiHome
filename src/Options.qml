pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Popup
{
    id: options

    modal: true
    focus: true

    property var settingsProvider

    Column
    {
        anchors.centerIn: parent
        spacing: 10

        Frame
        {
            ColumnLayout
            {
                anchors.fill: parent
                Switch
                {
                    text: qsTr("Show app labels on selection")
                    KeyNavigation.down: closeButton
                    Keys.onEnterPressed: checked = !checked
                    Keys.onReturnPressed: checked = !checked
                    checked: settingsProvider.showAppNames
                    onCheckedChanged: settingsProvider.showAppNames = checked
                }
            }
        }

        Row
        {
            spacing: 20

            Button
            {
                text: "Open System Settings"
                height: 60
                highlighted: activeFocus
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                onClicked: _Platform.openSettings()

                KeyNavigation.right: closeButton
            }

            Button
            {
                id: closeButton
                text: "Close"
                height: 60
                focus: true
                highlighted: activeFocus
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                onClicked: optionsPopup.close()
            }
        }
    }

}
