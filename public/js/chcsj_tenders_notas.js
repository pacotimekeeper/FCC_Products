let mybutton = document.getElementById("myBtn");

console.log('Button Element:', mybutton); // Check if the button is being found

// When the user scrolls down 20px from the top of the document, show the button
window.onscroll = function() {scrollFunction()};

// function scrollFunction() {
//   console.log('Scroll Position:', window.scrollY); // Log current scroll position for debugging
//   if (window.scrollY > 20) {
//     mybutton.style.display = "block";
//   } else {
//     mybutton.style.display = "none";
//   }
// }

// When the user clicks on the button, scroll to the top of the document
function topFunction() {
  console.log('Top Button Clicked'); // Log when the button is clicked
  document.body.scrollTop = 0;
  document.documentElement.scrollTop = 0;
}

function scrollFunction() {
  if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
    mybutton.style.display = "block";
  } else {
    mybutton.style.display = "none";
  }
}
