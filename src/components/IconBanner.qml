pragma ComponentBehavior: Bound
import QtQuick
import "ColorLogo.js" as ColorLogo

Item
{
    id: r
    required property string appPackage
    property bool loadTVBanner: true
    property bool async: false

    // background color based on app's dominant color, used when banner is not available or not wanted
    Rectangle
    {
        id: cover
        anchors.fill: parent
        visible: r.loadTVBanner && icon.status === Image.Ready
        color: visible ? ColorLogo.createByName(r.appPackage) : ""
    }

    Image
    {
        // 16:9 tv banner image | not available for all apps
        id: banner
        source: r.loadTVBanner ? "image://banner/" + r.appPackage : ""
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        cache: true
        asynchronous: r.async
    }

    Image
    {
        // app icon, loaded if banner image is not wanted or not available
        id: icon
        source: (banner.status === Image.Error || !r.loadTVBanner) ? "image://icon/" + r.appPackage : ""
        anchors.fill: parent
        anchors.margins: r.loadTVBanner ? 15 : 0
        fillMode: Image.PreserveAspectFit
        asynchronous: r.async
        cache: true
    }
}