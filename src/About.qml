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
        anchors.centerIn: parent
        spacing: 10

        Label
        {
            textFormat: Text.StyledText
            font.pixelSize: 20
            text: `<p>Thanks for supporting <strong>LetiHomePlus</strong> application!</p><br/>
            <strong>LetiHomePlus</strong> is a lightweight app launcher application<br/>
            that aims to works on as many TV devices as possible, <br/>especially low power ones.<br/><br/>
            As there is <u>zero</u> data collection, please provide your feedback <br/>and suggestions on project source page.<br/>
            <br/>
            <strong>OK</strong> opens current application.<br/>
            <strong>Menu</strong> or <strong>Back</strong> opens additional application options.<br/>
            `
        }

        Row
        {
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
