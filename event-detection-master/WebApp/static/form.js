/**
 * @fileoverview Form Validator
 * Provides validation for queries submitted through the web interface
 * @author Laura Biester and Anmol Raina
 */

 /**
  * Validates a query prior to posting the query-form to the server
  * Triggered on form-submit callback
  */
function submitQuery() {
  var form = document.forms["query-form"];
  var invalid = false;
  var list = document.getElementById("error-list");
  list.innerHTML = "";

  if (form["subject"].value == "") {
    addToList(list, "Subject is required");
    invalid = true;
  }
  if (form["verb"].value == "") {
    addToList(list, "Verb is required");
    invalid = true;
  }
  // a query is invalid if it has no contact information
  if (form["user-phone"].value == "" && form["user-email"].value == "") {
    addToList(list, "Either phone number or email is required");
    invalid = true;
  }

  // make sure email matches basic format - not 100% foolproof
  // regex from http://stackoverflow.com/questions/4964691/super-simple-email-validation-with-javascript
  if (form["user-email"].value != "") {
    var emailRe = /(.+)@(.+){2,}\.(.+){2,}/;
    if (!emailRe.test(form["user-email"].value)) {
    addToList(list, "Email must be valid");
    invalid = true;
    }
  }

  // make phone number only numeric, see if it has 10 digits
  if (form["user-phone"].value != "") {
    var phoneString = form["user-phone"].value;
    phoneString = phoneString.replace(/\D/g, "");
    if (phoneString.length == 10) {
      // 10 digits, accept
      form["user-phone"].value = phoneString;
    } else {
      addToList(list, "Phone numbers must have exactly 10 digits");
      invalid = true;
    }
  }

  // if the form is invalid, show the errors and don't submit
  if (invalid) {
    document.getElementById("form-error").className = "alert alert-danger";
    event.preventDefault();
    return false;
  }
}

/**
 * Adds an item to a given HTML list
 * @param {list} A html list to add an item to
 * @param {text} Text to add as an item to the list
 */
function addToList(list, text) {
  var entry = document.createElement("li");
  entry.appendChild(document.createTextNode(text));
  list.appendChild(entry);
}
