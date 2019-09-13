// Use local copy of JavaScript Cookie v2.2.1
$.getScript("/js/js.cookie.js");

// Get cookie consent if the UTC time zone is within the EU+ and user has not consented previously (no cookie exists)
$(document).ready(function() {
  // Show consent dialog if within EU time zone and either the cookie expired or does not exist
  if ( Cookies.get('site-cookie') == null ) {
    if (testEUtimezone()) {
      toggleconsent();
    }
  } else {
    console.log("You have already consented to cookie usage");
  }
});
// Use UTC to determine if the time zone resides in or around the EU (within UTC -1 to +6)
function testEUtimezone(){
  var offset = new Date().getTimezoneOffset();
  if ((offset >= -360) && (offset <= 60)) { // European time zones
    console.log("UTC time zone within the EU");
    return true;
  }
  console.log("UTC time zone is not within the EU");
  return false; // Not EU time zone
}
// Consent to cookie usage. Set expiration to 1 year.
function acceptcookie() {
  $( "#cookieModal" ).modal('hide');
  // set the cookie for 12 mns
  Cookies.set('site-cookie', 'accepted', { expires: 365 });
  console.log("I consent to the use of cookies on knative.dev");
}
// Show info about how to opt-out
function optout() {
  $( ".opt-out" ).toggle();
}

// Helpful commands (ie testing)

// Manually remove existing cookie
function removecookie(){
  Cookies.remove('site-cookie');
}
// Manually show cookie consent modal
function toggleconsent(){
  $("#cookieModal").modal('toggle');
}
// Manually check if the 'site-cookie' exists
function getcookie(){
  return Cookies.get('site-cookie');
}
