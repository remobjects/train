dgSearchIndex = {};
function searchhit(word) 
{ 
	var res = 0;
	for (var i = 0; i < word.length; i++)
	{
	  res = (((res << 5) - res) + word.charCodeAt(i)) & 0x7fffffff;
	}
	var mod = (res % dgSearchIndex.index.length);

	idx = dgSearchIndex.index[mod];
	if (idx)
		return idx[word];
	return null;
}
var havesessionStorage = false;
if (window.sessionStorage)
{
	try {
		window.sessionStorage.setItem("docgen", "docgen");
		window.sessionStorage.removeItem("docgen");
		havesessionStorage = true;
	} catch(e){ }
}

function search(s, cb) 
{
	if (havesessionStorage) 
	{
		try {
			var r = window.sessionStorage.getItem("docdatasearch");
			if (r)
			{
				r = JSON.parse(r);
				if (r && r.query == s) 
				{
					cb(r.data);
					return;
				}
			}
		} catch(e) {}
	}
	if (!dgSearchIndex.index) 
	{
		var head = document.getElementsByTagName('head')[0];
		var script = document.createElement('script');
		script.type = 'text/javascript';
		script.src = baseurl+"/js/searchindex.js";

		var func = function() {
			search(s, cb);
		};
		script.onreadystatechange = func;
		script.onload = func;

		head.appendChild(script);
		return;
	}
	 s= s.toLowerCase();
	 res = [];
	 var i = 0;
	 var mark = -1;
	 var wc = 0;
	 var pos = {};
	 while (i < s.length) 
	 {
		var ch = s.charAt(i);
		if ((ch >= 'a' && ch <='z' ) || ch == '_') 
		{
			mark = i;
			while (((ch >= 'a' && ch <='z' ) || ch == '_' || ch == '-' || (ch >= '0' && ch <= '9'))) 
			{
				i++;
				if (i >= s.length) break;
				ch = s.charAt(i);
			}
			var word = s.substring(mark, i);
			if (!dgSearchIndex.stopwords[word] && word.length >= 2)
			{
				var chit = searchhit(word);
				if (!chit) { cb(res); return; } // no hits
				wc++;
				for (var j = 0; j < chit.length / 2; j++) 
				{
					if (wc == 1)
						pos[chit[j * 2]] = [1, chit[j * 2+1]];
					else if (pos[chit[j*2]]) {
						var m = pos[chit[j * 2]];
						m[0] = wc;
						m.push(chit[j * 2+1]);
					}
				}
				if (wc != 1)	
				for(var el in pos)
				{
					var entry = pos[el];
					if (!entry) continue;
					if (entry[0] != wc)
						delete pos[el];
				}
			}
		} else i++;
	 }
	 if (wc == 0) { cb(res); return; }
	 for(var el in pos) 
	 {
		if (!el || !pos[el]) continue;
		res.push({ref: el, data: pos[el]});
	 }
	res.sort(function (a,b) { 
		if (a.length != b.length)
			return b.length - a.length;
		for (var i = 1; i < a.length; i++) 
		{
			if (a[i] != b[i])
				return b[i] - a[1];
		}
		return 0;
	});
	var realres = [];
	for (var i = 0; i < res.length; i++)
		realres[i] = dgSearchIndex.documents[res[i].ref];
	cb(realres); 
	if (havesessionStorage) 
	{
		try {
			window.sessionStorage.setItem("docdatasearch", JSON.stringify({query: s, data: realres}));
		} catch(e) {}
	}
	
}
function searchchanged(q)
{
	var ct = $(".main-content");
	unhighlight(ct, {className: "searchhit"});
	if (!q) 
	{
		$("div.maintoc").show();
		$("div.searchresults").hide();
		if (havesessionStorage) 
		{
			try {
				window.sessionStorage.removeItem("docdatasearch");
			} catch(e) {}
		}
	} else {
		$("div.maintoc").hide();
		var res = $("div.searchresults");
		res.show();
		
		search(q, function(s) {
			res.empty();
			if (s.length == 0) {
				var newul = $('<ul class="current" />');
				newul.append($('<span class="toctree-l0 searchresheader">No results</span>'));
				res.append(newul);
			} else {
				var newul = $('<ul class="current" />');
				newul.append($('<span class="toctree-l0 searchresheader">Search results</span>'));
				res.append(newul);
				for (var i = 0; i < s.length; i++) 
				{
					var el = s[i];
					var newdiv = $('<li class="toctree-l1" />');
					var newa = $("<a />");
					if (el.u == current)
						newdiv.addClass("current");
					// current
					newa.text(el.t);
					newa.attr("href", baseurl + el.u+"#q="+q);
					newdiv.append(newa);
					newul.append(newdiv);	
				}
			}
		})
		var m = q.replace(/[^a-zA-Z0-9_\-]/, ' ').split(' ');
		highlight(ct, m, {className: "searchhit", scrollToFirst: true});
	}
}


$( document ).ready(function() {
    // Shift nav in mobile when clicking the menu.
    $(document).on('click', "[data-toggle='navsel']", function() {
      $("[data-toggle='navshift']").toggleClass("shift");
    });
    // Close menu when you click a link.
    $(document).on('click', "tocmenu .current ul li a", function() {
      $("[data-toggle='navshift']").removeClass("shift");
    });

	$(window).on('beforeunload', function() {
		var nav = $(".sidenav");
		$.removeCookie("scrollpos");
		if (nav.get(0).scrollHeight > nav.get(0).clientHeight)
			$.cookie("scrollpos", nav.scrollTop(), {path: "/"});
	});
	var c = $.cookie("scrollpos");
	if (c) 
		$(".sidenav").scrollTop(c);
		
	var s = window.location.hash;
	if (s.length > 3 && s[0] == '#' && s[1] == 'q' && s[2] == '=') {
		nv = s.substring(3);
		$("#searchindexedit").val(nv);
		searchchanged(nv);
	}
    var inchange = false;

	$(window).bind( 'hashchange', function() {
	  if (inchange) return;
	  var s = window.location.hash;
	  if (s.length > 3 && s[0] == '#' && s[1] == 'q' && s[2] == '=') {
		nv = s.substring(3);
      } else  
	    nv = "";
	  $("#searchindexedit").val(nv);
	  searchchanged(nv);
	});
  
	$("#searchindexedit").keypress(function(e) {
		if (e.keyCode == 10 || e.keyCode == 13) {
			e.preventDefault();
			var newval =  $("#searchindexedit").val();
			inchange = true;
			if (newval == "")
				window.location.hash = "";
			else
				window.location.hash = "#q=" +newval;
			searchchanged(newval);
			inchange = false;
		}
    });
});


/* based on jQuery Highlight plugin by Bartek Szopka, highlight v3 by Johann Burkard 
 * http://johannburkard.de/blog/programming/javascript/highlight-javascript-text-higlighting-jquery-plugin.html
 * Licensed under MIT license.
 */

function inthighlight(node, re, nodeName, className, firstnode) {
	if (node.nodeType === 3) {
		var match = node.data.match(re);
		if (match) {
			var highlight = document.createElement(nodeName || 'span');
			if (firstnode && !firstnode.match)
				firstnode.match = highlight;
			highlight.className = className || 'highlight';
			var wordNode = node.splitText(match.index);
			wordNode.splitText(match[0].length);
			var wordClone = wordNode.cloneNode(true);
			highlight.appendChild(wordClone);
			wordNode.parentNode.replaceChild(highlight, wordNode);
			return 1; //skip added node in parent
		}
	} else if ((node.nodeType === 1 && node.childNodes) && // only element nodes that have children
			!/(script|style)/i.test(node.tagName) && // ignore script and style nodes
			!(node.tagName === nodeName.toUpperCase() && node.className === className)) { // skip if already highlighted
		for (var i = 0; i < node.childNodes.length; i++) {
			i += inthighlight(node.childNodes[i], re, nodeName, className, firstnode);
		}
	}
	return 0;
}

function unhighlight(node, options) {
	var settings = { className: 'highlight', element: 'span' };
	jQuery.extend(settings, options);
	return node.find(settings.element + "." + settings.className).each(function () {
		var parent = this.parentNode;
		parent.replaceChild(this.firstChild, this);
	parent.normalize();
	}).end();
};

function highlight(node, words, options) {
    var settings = { className: 'highlight', element: 'span', caseSensitive: false, wordsOnly: false, scrollToFirst: false };
    jQuery.extend(settings, options);
    
    if (words.constructor === String) {
        words = [words];
    }
    words = jQuery.grep(words, function(word, i){
      return word != '';
    });
    words = jQuery.map(words, function(word, i) {
      return word.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
    });
    if (words.length == 0) { return node; };

    var flag = settings.caseSensitive ? "" : "i";
    var pattern = "(" + words.join("|") + ")";
    if (settings.wordsOnly) {
        pattern = "\\b" + pattern + "\\b";
    }
	var firstnode = settings.scrollToFirst ? { } : null;
    var re = new RegExp(pattern, flag);
    
    var b = node.each(function () {
        inthighlight(this, re, settings.element, settings.className, firstnode);
    });
	
	if (firstnode && firstnode.match)
		firstnode.match.scrollIntoView(true);
	
	return b;
};
