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
        width: parent.width * 0.9
        anchors.centerIn: parent
        spacing: 20

        Label
        {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
            font.pixelSize: 20
            text: `<p>Thank you for supporting <strong>LetiHomePlus</strong>, a lightweight application launcher!</p>
            <h3>Features</h3>
            <ul>
                <li><strong>Grid/List</strong> for application display</li>
                <li><strong>Hide/Reorder</strong> current application</li>
                <li><strong>Wallpaper</strong> from Lorem Picsum</li>
                <li><strong>TV Input Switching</strong> support</li>
                <li><strong>OK</strong> opens current application.</li>
                <li><strong>Menu/Back</strong> opens additional application options</li>
            </li>
            `
        }

        Row
        {
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Button
            {
                id: reviewButton
                text: qsTr("Leave a review")
                height: 60
                highlighted: activeFocus
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
                Keys.onEnterPressed: clicked()
                onClicked: optionsPopup.close()
            }
        }

        Label
        {
            text:"As there is <u>zero</u> data collection, please provide your review on PlayStore or Github. Enjoy!"
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.WordWrap
            textFormat: Text.StyledText
        }
    }
}
