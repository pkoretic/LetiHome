.pragma library

// create color for a text input or index
const string_colors = [
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

function createByName(string)
{
    const index = Math.max(string.charCodeAt(string[0]) + string.charCodeAt(string.length - 1)) % string_colors.length
    return string_colors[index]
}

function createByIndex(index)
{
    return string_colors[index % string_colors.length]
}
