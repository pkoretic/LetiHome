pragma ComponentBehavior: Bound
import QtQuick
import "ColorLogo.js" as ColorLogo

Item
{
    id: iconBanner
    required property string appPackage
    property bool loadTVBanner: true

    Rectangle
    {
        id: cover
        anchors.fill: parent
        visible: loadTVBanner && icon.status === Image.Ready
        color: visible ? ColorLogo.createByName(appPackage) : ""
    }

    Image
    {
        // 16:9 tv banner image | not available for all apps
        id: banner
        source: loadTVBanner ? "image://banner/" + appPackage : ""
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        cache: true
    }

    Image
    {
        // app icon, loaded if banner image is not wanted or not available
        id: icon
        source: (banner.status === Image.Error || !loadTVBanner) ? "image://icon/" + appPackage : ""
        anchors.fill: parent
        anchors.margins: loadTVBanner ? 15 : 0
        fillMode: Image.PreserveAspectFit
        cache: true
    }
}