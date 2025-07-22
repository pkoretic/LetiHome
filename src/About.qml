pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material

Popup
{
    id: optionsPopup

    required property var navigationProvider

    modal: true
    focus: true

    closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnEscape

    Column
    {
        width: parent.width
        anchors.centerIn: parent
        spacing: 10

        Label
        {
            width: parent.width * 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            font.pixelSize: 20
            text: `<p>Thanks for supporting <strong>LetiHomePlus</strong> application!</p><br/>
            <strong>LetiHomePlus</strong> is a lightweight app launcher application that aims to work on as many TV devices as possible, especially low power ones.<br/><br/>
            As there is <u>zero</u> data collection, please provide your review on PlayStore, or feedback on project Github page.<br/>
            <br/>
            <strong>OK</strong> opens current application.<br/>
            <strong>Menu</strong> or <strong>Back</strong> opens additional application options.<br/>
            <strong>Options</strong> are in the right corner of the top menu.<br/>
            `
        }

        Row
        {
            width: parent.width * 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Button
            {
                id: reviewButton
                text: qsTr("Leave a review")
                height: 60
                highlighted: activeFocus
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                onClicked: navigationProvider.go("/appStore")

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
            }
        }
    }
}
