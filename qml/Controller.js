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
