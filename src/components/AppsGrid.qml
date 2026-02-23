pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material

// Grid view of applications
GridView
{
    id: gridView

    boundsBehavior: GridView.StopAtBounds

    cellWidth: (width / appsShown) |0
    cellHeight: cellWidth * 0.5625 // 9/16

    implicitHeight: childrenRect.height

    state: "default"
    states: [
        State { name: "default"; PropertyChanges { gridView.Keys.onPressed: event => defaultKeyHandler(event) }},
        State { name: "reorder"; PropertyChanges { gridView.Keys.onPressed: event => reorderKeyHandler(event) }}
    ]

    property bool isTelevision
    property bool showAppLabels
    property int appsShown: 5 // how many apps to show in grid

    signal openClicked(string packageName)
    signal infoClicked(string packageName)
    signal removeClicked(string packageName)
    signal orderChanged(var appsOrder)

    function openContextualMenu()
    {
        const x = gridView.currentItem.x + gridView.currentItem.width / 2
        const y = gridView.currentItem.y + gridView.currentItem.height / 2
        contextMenu.popup(x, y, menuOpen)
    }

    function getOrder()
    {
        let order = [] // packageName list
        for (let i = 0; i < gridView.model.count; i++)
            order.push(gridView.model.get(i).packageName)

        return order
    }

    function defaultKeyHandler(event)
    {
        switch (event.key)
        {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                event.accepted = true
                openClicked(gridView.currentItem.packageName)
            break

            case Qt.Key_Back:
            case Qt.Key_Menu:
            case Qt.Key_Escape:
                event.accepted = true
                openContextualMenu()
            break
        }
    }

    function reorderKeyHandler(event)
    {
        const currentIndex = gridView.currentIndex
        switch (event.key)
        {
            case Qt.Key_Back:
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Escape:
                event.accepted = true
                state = "default"
            break

            case Qt.Key_Right:
                event.accepted = true
                if (currentIndex < gridView.model.count-1)
                    gridView.model.move(currentIndex, currentIndex+1, 1)
                orderChanged(getOrder())
            break

            case Qt.Key_Left:
                event.accepted = true
                if (currentIndex > 0)
                    gridView.model.move(currentIndex, currentIndex-1, 1)
                orderChanged(getOrder())
            break

            case Qt.Key_Up:
                event.accepted = true
            break

            case Qt.Key_Down:
                event.accepted = true
            break
        }
    }

    // Contextual menu
    Menu
    {
        id: contextMenu
        MenuItem
        {
            id: menuOpen
            text: "Open"
            onTriggered: gridView.openClicked(gridView.currentItem.packageName)
        }
        MenuItem
        {
            text: "Info"
            onTriggered: gridView.infoClicked(gridView.currentItem.packageName)
        }
        MenuItem
        {
            text: "Reorder"
            onTriggered: gridView.state = "reorder"
        }
        MenuItem
        {
            text: "Hide"
            onTriggered:
            {
                gridView.removeClicked(gridView.currentItem.packageName)

                // due to Menu being native popup, we need to force focus back to GridView
                gridView.forceActiveFocus()
            }
        }
    }

    delegate: IconBanner
    {
        id: delegate

        required property int index
        required property var model
        property bool isCurrentItem: activeFocus && GridView.isCurrentItem
        property string packageName: model.packageName

        width: GridView.view.cellWidth - 20
        height: width * 0.5625 // 9/16

        z: delegate.isCurrentItem ? 1 : 0
        scale: delegate.isCurrentItem && gridView.state === "default" ? 1.3 : 1
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }

        appPackage: delegate.packageName

        // app name background so it's readable on any background image
        Rectangle
        {
            visible: gridView.showAppLabels && gridView.isTelevision && delegate.isCurrentItem
            width: parent.width
            height: appName.height
            anchors.bottom: parent.bottom
            color: Qt.color("#a6000000")
        }

        // app name
        Text
        {
            id: appName
            x: 4
            width: parent.width - x * 2
            text: model.applicationName
            color: Qt.color("#ffffff")
            elide: Text.ElideRight
            anchors.bottom: parent.bottom
            visible: gridView.showAppLabels && delegate.isCurrentItem || !gridView.isTelevision
            horizontalAlignment: Text.AlignHCenter
        }

        // border around current item
        Rectangle
        {
            anchors.fill: parent
            visible: delegate.isCurrentItem
            color: Qt.color("transparent")
            border.width: gridView.state === "reorder" ? 3 : 2
            border.color: gridView.state === "reorder" ? Qt.color("red") : Qt.color("#222222")
        }
    }
}
