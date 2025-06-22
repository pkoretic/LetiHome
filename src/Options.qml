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
                    text: qsTr("Align apps to bottom")
                    Keys.onEnterPressed: checked = !checked
                    Keys.onReturnPressed: checked = !checked
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
                    Keys.onReturnPressed: checked = !checked
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
                    Keys.onReturnPressed: checked = !checked
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
        }
    }

    Component
    {
        id: appsTab

          Column
          {
              width: parent.width
              height: parent.height
              spacing: 20

              Label
              {
                text: qsTr("Hidden apps - press <strong>OK</strong> to unhide")
              }

              ListView
              {
                  id: allAppsList
                  width: parent.width - 20
                  height: 100
                  spacing: 10
                  z: 1
                  anchors.horizontalCenter: parent.horizontalCenter

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
                text: allAppsList.currentItem?.applicationName || qsTr("All apps shown")
                font.bold: true
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
