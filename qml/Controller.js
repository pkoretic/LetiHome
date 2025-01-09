function init()
{
    loadApplications();
}

// controllers
function loadApplications()
{
    appGrid.model = _Platform.applicationList()
}

function openApplication(packageName)
{
    if(packageName === "hr.envizia.letihome")
        optionsPopup.open()
    else
        _Platform.openApplication(packageName)
}

function openAppInfo(packageName)
{
    _Platform.openAppInfo(packageName)
}

function openSettings()
{
    _Platform.openSettings()
}

function openLetiHomePage()
{
    _Platform.openLetiHomePage()
}

function updateDate()
{
    root.currentDate = new Date()
}

function onKeyPress(event)
{
    event.accepted = true
    const packageName = appGrid.model[appGrid.currentIndex].packageName

    switch(event.key)
    {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            openApplication(packageName)
        break

        case Qt.Key_Back:
        case Qt.Key_Esc:
            openAppInfo(packageName)
        break

        case Qt.Key_Menu:
            openSettings()
        break

        default:
            event.accepted = false
    }
}

// create color for a text input or index
var string_colors = [
    "#115883",
    "#536173",
    "#33b679",
    "#aeb857",
    "#df5948",
    "#855e86",
    "#ae6b23",
    "#547bca",
    "#c75c5c",
]

var logoByName = function(string)
{
    var index = Math.max(string.charCodeAt(string[0]) + string.charCodeAt(string.length - 1)) % string_colors.length

    return string_colors[index]
}

var logoByIndex = function(index)
{
    return string_colors[index % string_colors.length]
}
