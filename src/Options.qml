pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Effects

import "components"

Popup
{
    id: r

    modal: true
    focus: true

    required property var settingsProvider
    required property var navigationProvider
    required property var appsProvider
    required property var platformProvider

    // Tab name to index mapping
    readonly property var tabIndices: { "options": 0, "apps": 1, "system": 2 }
    property string initialTab: "options"

    Component.onCompleted: tabBar.setCurrentIndex(-1) // start unloaded
    onOpened: {
        tabBar.setCurrentIndex(tabIndices[initialTab] ?? 0)
        initialTab = "options" // reset for next open
    }
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
            case 0: contentLoader.sourceComponent = optionsTab; optionsTabButton.forceActiveFocus(); break
            case 1: contentLoader.sourceComponent = appsTab; appsTabButton.forceActiveFocus(); break
            case 2: contentLoader.sourceComponent = systemTab; systemTabButton.forceActiveFocus(); break
        }

        TabButton
        {
            id: optionsTabButton
            text: qsTr("Options")
        }

        TabButton
        {
            id: appsTabButton
            text: qsTr("Apps")
        }

        TabButton
        {
            id: systemTabButton
            text: qsTr("System")
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
            Column
            {
                spacing: 20
                Switch
                {
                    id: showAppLabelsSwitch
                    text: qsTr("Show app labels on selection")
                    Keys.onEnterPressed: checked = !checked
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
                    Keys.onLeftPressed: checked = false
                    Keys.onRightPressed: checked = true
                    checked: settingsProvider.showDate
                    onCheckedChanged: settingsProvider.showDate = checked

                    KeyNavigation.up: showClockSwitch
                }

                Switch
                {
                    id: alignToBottomSwitch
                    text: qsTr("Align apps to bottom")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onLeftPressed: checked = false
                    Keys.onRightPressed: checked = true
                    checked: settingsProvider.alignToBottom
                    onCheckedChanged: settingsProvider.alignToBottom = checked

                    KeyNavigation.up: showDateSwitch
                }

                Switch
                {
                    id: showAsListSwitch
                    text: qsTr("Show as list instead of a grid")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onLeftPressed: checked = false
                    Keys.onRightPressed: checked = true
                    checked: settingsProvider.showAsList
                    onCheckedChanged: settingsProvider.showAsList = checked

                    KeyNavigation.up: alignToBottomSwitch
                }

                Switch
                {
                    id: loremPicsumBackgroundSwitch
                    text: qsTr("Use Random (Lorem Picsum) Wallpaper")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onLeftPressed: checked = false
                    Keys.onRightPressed: checked = true
                    checked: settingsProvider.useLoremPicsumWallpaper
                    onCheckedChanged: settingsProvider.useLoremPicsumWallpaper = checked

                    KeyNavigation.up: showAsListSwitch
                    KeyNavigation.down: appsShownSpinBox
                }

                // Input field that allows to change the number of apps shown in the grid/list

                Row
                {
                    spacing: 10
                    SpinBox
                    {
                        id: appsShownSpinBox
                        height: loremPicsumBackgroundSwitch.height
                        from: 3
                        to: 10
                        value: settingsProvider.appsShown
                        onValueChanged: settingsProvider.appsShown = value

                        Keys.onLeftPressed: value = Math.max(from, value - 1)
                        Keys.onRightPressed: value = Math.min(to, value + 1)
                        Keys.onUpPressed: { loremPicsumBackgroundSwitch.focus = true; loremPicsumBackgroundSwitch.focusReason = Qt.ShortcutFocusReason }
                        Keys.onDownPressed: {}
                    }
                    Label
                    {
                        text: qsTr("Number of apps shown (Press Left/Right to change)")
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Image
            {
                id: imagePreview
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height / 2
                width: height
                fillMode: Image.PreserveAspectCrop
                visible: settingsProvider.useLoremPicsumWallpaper
                source: visible ? settingsProvider.wallpaperUrl : "" // unload when not visible

                // rounded corners
                layer.enabled: visible
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: Rectangle {
                            width: imagePreview.width
                            height: imagePreview.height
                            radius: 10
                        }
                        hideSource: true  // hides from scene but still renders to texture
                        live: false       // static mask, no need to update every frame
                    }
                }
                Label
                {
                    text: qsTr("Wallpaper preview")
                    font.italic: true
                    style: Label.Outline
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    Component
    {
        id: appsTab

        GroupBox
        {
            Column
            {
                width: parent.width
                height: parent.height
                spacing: 20

                Label
                {
                    text: qsTr("Hidden apps")
                    font.bold: true
                    font.pixelSize: 18
                }

                ListView
                {
                    id: allAppsList
                    width: parent.width - 20
                    height: 100
                    spacing: 10
                    z: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: appModel.count != 0

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
                    KeyNavigation.up: appsTabButton

                    delegate: IconBanner
                    {
                        property bool isCurrentItem: ListView.isCurrentItem && activeFocus
                        required property var model
                        property string applicationName: model.applicationName
                        loadTVBanner: false
                        async: true

                        height: ListView.view.height - 20
                        width: height

                        appPackage: model.packageName

                        scale: isCurrentItem ? 1.3 : 1
                        z: isCurrentItem ? 1 : 0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
                    }
                }

                Label
                {
                    text: qsTr("Press <strong>OK</strong> to unhide <strong>%1</strong>").arg(allAppsList.currentItem?.applicationName)
                    font.pixelSize: 18
                    visible: allAppsList.activeFocus && appModel.count != 0
                }

                Label
                {
                    text: qsTr("All apps shown")
                    visible: appModel.count === 0
                    font.italic: true
                }

            }
        }
    }

    Component
    {
        id: systemTab

        GroupBox
        {
            Column
            {
                width: parent.width
                spacing: 20

                Label
                {
                    text: qsTr("TV Inputs")
                    font.bold: true
                    font.pixelSize: 18
                }

                ListView
                {
                    id: tvInputsListView
                    width: parent.width
                    height: 60
                    spacing: 10
                    clip: true
                    orientation: ListView.Horizontal

                    visible: tvInputsModel.count != 0

                    model: ListModel { id: tvInputsModel }

                    Component.onCompleted:
                    {
                        const inputs = platformProvider.getTvInputs()
                        for (let i = 0; i < inputs.length; i++)
                            tvInputsModel.append(inputs[i])
                    }

                    KeyNavigation.up: systemTabButton

                    delegate: Button
                    {
                        required property var model
                        height: ListView.view.height
                        text: model.inputLabel
                        highlighted: activeFocus
                        Keys.onEnterPressed: clicked()
                        onClicked: platformProvider.setTvInput(model.inputId)
                    }
                }

                Label
                {
                    text: qsTr("No TV inputs found")
                    visible: tvInputsModel.count === 0
                    font.italic: true
                }

                Label
                {
                    text: qsTr("System settings")
                    font.bold: true
                    font.pixelSize: 18
                }

                Button
                {
                    id: openSettingsButton
                    text: qsTr("Open")
                    height: 60
                    highlighted: activeFocus
                    Keys.onEnterPressed: clicked()
                    onClicked: navigationProvider.go("/systemsettings")
                    KeyNavigation.up: tvInputsListView
                }
            }
        }
    }
}
