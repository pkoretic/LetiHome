pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material

import "components"

Popup
{
    id: optionsPopup

    modal: true
    focus: true

    required property var settingsProvider
    required property var navigationProvider
    required property var appsProvider

    Component.onCompleted: tabBar.setCurrentIndex(-1) // start unloaded
    onOpened: { tabBar.setCurrentIndex(0); optionsTabButton.forceActiveFocus() } // load
    onClosed: tabBar.setCurrentIndex(-1) // unload

    padding: 0

    TabBar
    {
        id: tabBar

        width: parent.width
        height: 60

        onCurrentIndexChanged: switch (currentIndex)
        {
            case -1: contentLoader.sourceComponent = undefined; break
            case 0: contentLoader.sourceComponent = optionsTab; break
            case 1: contentLoader.sourceComponent = appsTab; break
            case 2: contentLoader.sourceComponent = systemTab; break
        }

        TabButton
        {
            id: optionsTabButton
            text: qsTr("Options")
            onClicked: tabBar.currentIndex = 0
        }

        TabButton
        {
            id: appsTabButton
            text: qsTr("Apps")
            onClicked: tabBar.currentIndex = 1
        }

        TabButton
        {
            id: systemTabButton
            text: qsTr("System")
            onClicked: tabBar.currentIndex = 2
        }
    }

    Loader
    {
        id: contentLoader
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        asynchronous: true
    }

    Component
    {
        id: optionsTab
        GroupBox
        {
            title: qsTr("Options")
            Column
            {
                spacing: 20
                Switch
                {
                    id: showAppLabelsSwitch
                    text: qsTr("Show app labels on selection")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onReturnPressed: checked = !checked
                    Keys.onLeftPressed: checked = false
                    Keys.onRightPressed: checked = true
                    checked: settingsProvider.showAppNames
                    onCheckedChanged: settingsProvider.showAppNames = checked
                    KeyNavigation.up: optionsTabButton
                }
                Switch
                {
                    id: showClockSwitch
                    text: qsTr("Show clock")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onReturnPressed: checked = !checked
                    Keys.onLeftPressed: checked = false
                    Keys.onRightPressed: checked = true
                    checked: settingsProvider.showClock
                    onCheckedChanged: settingsProvider.showClock = checked

                    KeyNavigation.up: showAppLabelsSwitch
                }
                Switch
                {
                    id: showDateSwitch
                    text: qsTr("Show date")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onReturnPressed: checked = !checked
                    Keys.onLeftPressed: checked = false
                    Keys.onRightPressed: checked = true
                    checked: settingsProvider.showDate
                    onCheckedChanged: settingsProvider.showDate = checked

                    KeyNavigation.up: showClockSwitch
                }
                Switch
                {
                    id: alignToBottomSwitch
                    text: qsTr("Align apps grid to bottom")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onReturnPressed: checked = !checked
                    Keys.onLeftPressed: checked = false
                    Keys.onRightPressed: checked = true
                    checked: settingsProvider.alignToBottom
                    onCheckedChanged: settingsProvider.alignToBottom = checked

                    KeyNavigation.up: showDateSwitch
                }
            }
        }
    }

    Component
    {
        id: appsTab

        Column
        {
            anchors.centerIn: parent
            width: parent.width / 2
            spacing: 10

            Column
            {
                width: parent.width
                spacing: 10

                GroupBox
                {
                    title: qsTr("Manage apps visibility")
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

                        highlightMoveDuration: 150

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

                        Component.onCompleted: loadModel()

                        Keys.onEnterPressed: addApp(appModel.get(currentIndex).packageName)
                        Keys.onReturnPressed: addApp(appModel.get(currentIndex).packageName)
                        KeyNavigation.up: appsTabButton

                        delegate: IconBanner
                        {
                            property bool isCurrentItem: ListView.isCurrentItem && activeFocus
                            required property var model
                            property string applicationName: model.applicationName
                            loadTVBanner: false
                            async: true

                            width: (allAppsList.width / 6) |0
                            height: width

                            appPackage: model.packageName

                            scale: isCurrentItem ? 1 : 0.7
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                        }
                    }

                    Label
                    {
                        text: allAppsList.currentItem?.applicationName || qsTr("All apps shown")
                        anchors.bottom: parent.bottom
                    }
                }

            }

        }
    }

    Component
    {
        id: systemTab

        Item
        {
            Button
            {
                text: qsTr("Open System Settings")
                height: 60
                highlighted: activeFocus
                Keys.onEnterPressed: clicked()
                Keys.onReturnPressed: clicked()
                onClicked: navigationProvider.go("/systemsettings")
                KeyNavigation.up: systemTabButton
            }
        }
    }
}
