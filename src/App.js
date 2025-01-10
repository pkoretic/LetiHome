function init()
{
    loadApplications();
}

// controllers
function loadApplications()
{
    appsGrid.model = _Platform.applicationList()
}

function openApplication(packageName)
{
    if(packageName === "hr.envizia.letihome")
        aboutPopup.open()
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

function onKeyPress(event)
{
    event.accepted = true
    const packageName = appsGrid.model[appsGrid.currentIndex].packageName

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
