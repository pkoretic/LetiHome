pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material

// List view of applications
ListView {
    id: listView

    boundsBehavior: ListView.StopAtBounds

    orientation: Qt.Horizontal
    highlightRangeMode: ListView.ApplyRange
    highlightMoveDuration: 150
    highlightFollowsCurrentItem: true
    spacing: 10

    property int appsShown: 5
    property int delegateWidth: (width / appsShown) | 0
    property int delegateHeight: delegateWidth * 0.5625 // 9/16


    height: delegateHeight

    state: "default"
    states: [
        State {
            name: "default"
            PropertyChanges {
                listView.Keys.onPressed: event => defaultKeyHandler(event)
            }
        },
        State {
            name: "reorder"
            PropertyChanges {
                listView.Keys.onPressed: event => reorderKeyHandler(event)
            }
        }
    ]

    property bool isTelevision
    property bool showAppLabels

    signal openClicked(string packageName)
    signal infoClicked(string packageName)
    signal removeClicked(string packageName)
    signal orderChanged(var appsOrder)

    function openContextualMenu() {
        // highlight is always at first item
        const x = listView.currentItem.width / 2;
        const y = listView.currentItem.y + listView.currentItem.height / 2;
        contextMenu.popup(x, y, menuOpen);
    }

    function getOrder() {
        let order = []; // packageName list
        for (let i = 0; i < listView.model.count; i++)
            order.push(listView.model.get(i).packageName);

        return order;
    }

    function defaultKeyHandler(event) {
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            event.accepted = true;
            openClicked(listView.currentItem.packageName);
            break;
        case Qt.Key_Back:
        case Qt.Key_Menu:
        case Qt.Key_Escape:
            event.accepted = true;
            openContextualMenu();
            break;
        }
    }

    function reorderKeyHandler(event) {
        const currentIndex = listView.currentIndex;
        switch (event.key) {
        case Qt.Key_Back:
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Escape:
            event.accepted = true;
            state = "default";
            break;
        case Qt.Key_Right:
            event.accepted = true;
            if (currentIndex < listView.model.count - 1)
                listView.model.move(currentIndex, currentIndex + 1, 1);
            orderChanged(getOrder());
            break;
        case Qt.Key_Left:
            event.accepted = true;
            if (currentIndex > 0)
                listView.model.move(currentIndex, currentIndex - 1, 1);
            orderChanged(getOrder());
            break;
        }
    }

    // Contextual menu
    Menu {
        id: contextMenu
        MenuItem {
            id: menuOpen
            text: "Open"
            onTriggered: listView.openClicked(listView.currentItem.packageName)
        }
        MenuItem {
            text: "Info"
            onTriggered: listView.infoClicked(listView.currentItem.packageName)
        }
        MenuItem {
            text: "Reorder"
            onTriggered: listView.state = "reorder"
        }
        MenuItem {
            text: "Remove"
            onTriggered: {
                listView.removeClicked(listView.currentItem.packageName);

                // due to Menu being native popup, we need to force focus back to ListView
                listView.forceActiveFocus();
            }
        }
    }

    delegate: IconBanner {
        id: delegate

        required property int index
        required property var model
        property bool isCurrentItem: activeFocus && ListView.isCurrentItem
        property string packageName: model.packageName

        // width: parent.width - 20
        // height: width * 0.5625 // 9/16

        width: listView.delegateWidth
        height: listView.delegateHeight

        z: delegate.isCurrentItem ? 1 : 0
        scale: delegate.isCurrentItem && listView.state === "default" ? 1.3 : 1
        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }

        appPackage: delegate.packageName

        // app name background so it's readable on any background image
        Rectangle {
            visible: listView.showAppLabels && listView.isTelevision && delegate.isCurrentItem
            width: parent.width
            height: appName.height
            anchors.bottom: parent.bottom
            color: "#a6000000"
        }

        // app name
        Text {
            id: appName
            x: 4
            width: parent.width - x * 2
            text: model.applicationName
            color: "#ffffff"
            elide: Text.ElideRight
            anchors.bottom: parent.bottom
            visible: listView.showAppLabels && delegate.isCurrentItem || !listView.isTelevision
            horizontalAlignment: Text.AlignHCenter
        }

        // border around current item
        Rectangle {
            anchors.fill: parent
            visible: delegate.isCurrentItem
            color: "transparent"
            border.width: listView.state === "reorder" ? 3 : 2
            border.color: listView.state === "reorder" ? "red" : "#222222"
        }
    }
}
