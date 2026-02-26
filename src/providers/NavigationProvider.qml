pragma ComponentBehavior: Bound

import QtQuick

Item
{
    id: navigator

    property var views: []

    // Options tab index constants
    readonly property int tabOptions: 0
    readonly property int tabApps: 1
    readonly property int tabSystem: 2

    // views = { home: homeView, options: optionsView, about: aboutView }
    function init(views)
    {
        navigator.views = views
    }

    function go(viewName, properties)
    {
        const viewOrNavigation= navigator.views[viewName]
        if (!viewOrNavigation)
            return console.error("View not found:", viewName)

        if (viewOrNavigation.open) {
            if (properties)
                Object.assign(viewOrNavigation, properties)
            viewOrNavigation.open()
        }
        else
            viewOrNavigation()
    }
}