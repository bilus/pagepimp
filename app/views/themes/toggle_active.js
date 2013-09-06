
if ( $("#<%= dom_id(@theme) %>").length > 1 ){  // Browse themes site
  $("#<%= dom_id(@theme) %>").replaceWith($("<%= j render @theme %>"));
} else {
  window.location.reload();
}

