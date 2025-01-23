pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import "components"

Popup
{
    id: optionsPopup

    modal: true
    focus: true

    required property var settingsProvider
    required property var navigationProvider
    required property var appsProvider

    Column
    {
        anchors.centerIn: parent
        width: parent.width / 2
        spacing: 40

        Column
        {
            width: parent.width
            spacing: 30

            GroupBox
            {
                title: qsTr("Add app")
                width: parent.width
                height: 150

                ListView
                {
                    id: allAppsList
                    width: parent.width
                    height: 150
                    spacing: 10
                    clip: true
                    model: ListModel { id: appModel }

                    orientation: ListView.Horizontal
                    snapMode: ListView.SnapToItem

                    function loadModel()
                    {
                        const apps = appsProvider.getAvailableApps();
                        for (let i = 0; i < apps.length; i++)
                            appModel.set(i, apps[i])
                    }

                    function addApp(packageName)
                    {
                        // add it to domain data model
                        appsProvider.addApp(packageName)

                        // update view data model
                        for (let i = 0; i < appModel.count; i++)
                            if (appModel.get(i).packageName === packageName)
                                return appModel.remove(i)
                    }

                    onVisibleChanged: visible && loadModel()

                    Keys.onEnterPressed: addApp(appModel.get(currentIndex).packageName)
                    Keys.onReturnPressed: addApp(appModel.get(currentIndex).packageName)

                    delegate: IconBanner
                    {
                        property bool isCurrentItem: ListView.isCurrentItem && activeFocus
                        required property var model
                        property string applicationName: model.applicationName
                        loadTVBanner: false

                        width: (allAppsList.width / 6) |0
                        height: width

                        appPackage: model.packageName

                        scale: isCurrentItem ? 1 : 0.7
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                    }
                }

                Label
                {
                    text: allAppsList.currentItem?.applicationName || qsTr("All apps added")
                    anchors.bottom: parent.bottom
                }
            }

            GroupBox
            {
                title: qsTr("Options")
                Switch
                {
                    id: showAppLabelsSwitch
                    text: qsTr("Show app labels on selection")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onReturnPressed: checked = !checked
                    checked: settingsProvider.showAppNames
                    onCheckedChanged: settingsProvider.showAppNames = checked

                    KeyNavigation.up: allAppsList
                }
            }
        }

        Row
        {
            spacing: 20

            Button
            {
                text: qsTr("Open System Settings")
                height: 60
                highlighted: activeFocus
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                onClicked: navigationProvider.go("/systemsettings")

                KeyNavigation.up: showAppLabelsSwitch
                KeyNavigation.right: closeButton
            }

            Button
            {
                id: closeButton
                text: qsTr("Close")
                height: 60
                focus: true
                highlighted: activeFocus
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                onClicked: optionsPopup.close()

                KeyNavigation.up: showAppLabelsSwitch
            }
        }
    }
}
