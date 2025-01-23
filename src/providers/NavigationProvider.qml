pragma ComponentBehavior: Bound

import QtQuick

Item
{
    id: navigator

    property var views: []

    // views = { home: homeView, options: optionsView, about: aboutView }
    function init(views)
    {
        navigator.views = views
    }

    function go(viewName)
    {
        const viewOrNavigation= navigator.views[viewName]
        if (!viewOrNavigation)
            return console.error("View not found:", viewName)

        if (viewOrNavigation.open)
            viewOrNavigation.open()
        else
            viewOrNavigation()
    }
}