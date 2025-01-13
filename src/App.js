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
    // open internal pages
    if(packageName === "hr.envizia.letihome")
        letiHomeContextMenu.popup(appsGrid.currentItem)
    else
        _Platform.openApplication(packageName)
}

function openAbout()
{
    aboutPopup.open()
}

function openOptions()
{
    optionsPopup.open()
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
        case Qt.Key_Escape:
            appsGrid.openContextualMenu()
        break

        case Qt.Key_Menu:
            openSettings()
        break

        default:
            event.accepted = false
    }
}
