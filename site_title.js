var blink_speed = 1000
var type_speed = 100
var title_start = "> IsaacMarovitz\\";

var page_title = $('#page-title').val();
var element = document.getElementById('nav-title');
element.innerText = title_start;
dash_enabled = false;

document.title = "Isaac Marovitz - " + page_title;

var i = 0;
function typeWriter() {
    if (i < page_title.length) {
        element.innerText += page_title.charAt(i);
        i++;
        setTimeout(typeWriter, type_speed);
    } else {
        setInterval(() => {
            if (dash_enabled) {
                element.innerText = element.innerText.slice(0, -1);
                dash_enabled = false;
            } else {
                element.innerText += "_";
                dash_enabled = true;
            }
        }, blink_speed);
    }
}

typeWriter();
