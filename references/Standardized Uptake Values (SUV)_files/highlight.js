/*-----------------------------------------
///////////////////////////////////////////
HIGHLIGHT SEARCH TEXT QUERY IN ROBOHELP X5
	November 19,2004--
	Created by Calvin Ly--
///////////////////////////////////////////
-----------------------------------------*/


/*----------------------------------
Get Location of the Search Form Page
For some reason, the location of the frames switches 
when you go back and forth from different sections
------------------------------------*/
function searchLocValue1 () {
	return parent.frames[0].frames[1].frames[0].ftsform.document.FtsInputForm.keywordField.value;
}

function searchLocValue2 () {
	return parent.frames[0].frames[1].frames[1].ftsform.document.FtsInputForm.keywordField.value;
} 

function searchLocValue3 () {
	return parent.frames[0].frames[1].frames[2].ftsform.document.FtsInputForm.keywordField.value;
} 


/*-------------------------------------
BEGIN SEARCH PROCESS
This must be called when the page finishes loading
<body onload="beginSearch();">
---------------------------------------*/
function beginSearch () {
	//Get the current state of the left pane bar 
	var oMsg=new whMessage(WH_MSG_GETPANEINFO,this,1,null);
	
	//If the current state is on the search section then check search string
	if(SendMessage(oMsg)) {
		if (oMsg.oParam == "fts") {
			//The parent frame of the search form is within 'whfdhtml.htm' 
			//For some reason the frames get changes to different locations when different sections are clicked
			//So we must create two locations to see if the the parent page is 'whfdhtml.htm'
			var myloc = parent.frames[0].frames[1].frames[0].location.toString();
			var myloc2 = parent.frames[0].frames[1].frames[1].location.toString();

			//check for parent page
			var checkValid = myloc.indexOf('whfdhtml');
			if (checkValid > 0) { //true
				var searchField = searchLocValue1();
			} else {
				var checkValid = myloc2.indexOf('whfdhtml');
				if(checkValid > 0) { // true
					var searchField = searchLocValue2 ();
				} else {
					var searchField = searchLocValue3 ();
				}
			}
			//check if searchField is empty
			if (searchField != "" && searchField != null && searchField != "undefined") {
				//call function to highlight
				highlightSearchTerms(searchField);
			}
		} // end check for left pane
		
	} // end check if message was sent
} //end function


/*-------------------------------------------------------------------
 * This is the function that actually highlights a text string by
 * adding HTML tags before and after all occurrences of the search
 * term. You can pass your own tags if you'd like, or if the
 * highlightStartTag or highlightEndTag parameters are omitted or
 * are empty strings then the default <font> tags will be used.
 --------------------------------------------------------------------*/
function doHighlight(bodyText, searchTerm, highlightStartTag, highlightEndTag) 
{
  // the highlightStartTag and highlightEndTag parameters are optional
  if ((!highlightStartTag) || (!highlightEndTag)) {
    highlightStartTag = "<font style='color:blue; background-color:yellow;'>";
    highlightEndTag = "</font>";
  }
  
  // find all occurences of the search term in the given text,
  // and add some "highlight" tags to them (we're not using a
  // regular expression search, because we want to filter out
  // matches that occur within HTML tags and script blocks, so
  // we have to do a little extra validation)
  var newText = "";
  var i = -1;
  var lcSearchTerm = searchTerm.toLowerCase();
  var lcBodyText = bodyText.toLowerCase();
    
  while (bodyText.length > 0) {
    i = lcBodyText.indexOf(lcSearchTerm, i+1);
    if (i < 0) {
      newText += bodyText;
      bodyText = "";
    } else {
      // skip anything inside an HTML tag
      if (bodyText.lastIndexOf(">", i) >= bodyText.lastIndexOf("<", i)) {
        // skip anything inside a <script> block
        if (lcBodyText.lastIndexOf("/script>", i) >= lcBodyText.lastIndexOf("<script", i)) {
          newText += bodyText.substring(0, i) + highlightStartTag + bodyText.substr(i, searchTerm.length) + highlightEndTag;
          bodyText = bodyText.substr(i + searchTerm.length);
          lcBodyText = bodyText.toLowerCase();
          i = -1;
        }
      }
    }
  }
  
  return newText;
}


/*-------------------------------------------------------------------
 * This is sort of a wrapper function to the doHighlight function.
 * It takes the searchText that you pass, optionally splits it into
 * separate words, and transforms the text on the current web page.
 * Only the "searchText" parameter is required; all other parameters
 * are optional and can be omitted.
 -------------------------------------------------------------------*/
function highlightSearchTerms(searchText, treatAsPhrase, warnOnFailure, highlightStartTag, highlightEndTag)
{
  // if the treatAsPhrase parameter is true, then we should search for 
  // the entire phrase that was entered; otherwise, we will split the
  // search string so that each word is searched for and highlighted
  // individually
  if (treatAsPhrase) {
    searchArray = [searchText];
  } else {
    searchArray = searchText.split(" ");
  }
  
  if (!document.body || typeof(document.body.innerHTML) == "undefined") {
    if (warnOnFailure) {
      alert("Sorry, for some reason the text of this page is unavailable. Searching will not work.");
    }
    return false;
  }
  
  var bodyText = document.body.innerHTML;
  for (var i = 0; i < searchArray.length; i++) {
	var string = searchArray[i];

	//remove parenthesis and commas
	string = string.replace('(','');
	string = string.replace(')','');
	string = string.replace(',','');

	//remove boolean operators
	if (string.indexOf("AND") == -1 && string.indexOf("OR") == -1 && string.indexOf("NEAR") == -1) {
		//do not search for empty characters
		 if (string != "") {
			 bodyText = doHighlight(bodyText, searchArray[i], highlightStartTag, highlightEndTag);
		 }
	}
  }
  
  document.body.innerHTML = bodyText;
  return true;
}