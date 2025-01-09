import QtQuick
import QtQuick.Controls.Material

import "./Controller.js" as Controller

Popup
{
    id: optionsPopup

    width: parent.width * 0.9
    height: parent.height * 0.9
    anchors.centerIn: parent
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
            text: `<p>Thanks for using <strong>LetiHome</strong> application!</p><br/>
            <strong>LetiHome</strong> is a lightweight app launcher application<br/>
            that aims to works on as many TV devices as possible, <br/>especially low power ones.<br/><br/>
            As there is <u>zero</u> data collection, please provide your feedback <br/>and suggestions on project source page.<br/>
            `
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
                onClicked: Controller.openSettings()

                KeyNavigation.right: reviewButton
            }

            Button
            {
                id: reviewButton
                text: "Leave a review"
                height: 60
                highlighted: activeFocus
                Keys.onReturnPressed: clicked()
                Keys.onEnterPressed: clicked()
                onClicked: Controller.openLetiHomePage()

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
