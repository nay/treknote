// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function scale_down_size(maxWidth, maxHeight, naturalWidth, naturalHeight) {
    var w = naturalWidth / maxWidth;
    var h = naturalHeight / maxHeight;
    if (h <= 1 && w <= 1) {
      return {width: naturalWidth, height: naturalHeight};
    }
    var m = h >= w ? h: w;
    return {width: Math.round(naturalWidth / m), height: Math.round(naturalHeight / m)};
}


function visiblePageNumbers(currentPage, totalPages, innerWindow, outerWindow) {
  if (innerWindow == undefined) { innerWindow = 4; }
  if (outerWindow == undefined) { outerWindow = 1; }
  var windowFrom = currentPage - innerWindow;
  var windowTo = currentPage + innerWindow;
  
  if (windowTo > totalPages) {
    windowFrom -= windowTo - totalPages;
    windowTo = totalPages;
  }
  if (windowFrom < 1) {
    windowTo += 1 - windowFrom;
    windowFrom = 1;
    if (windowTo > totalPages) {
      windowTo = totalPages;
    }
  }
  visible = new Array();
  for (var i = 1; i <= totalPages; i++) {
    visible.push(i);
  }
  leftGap = new Array();
  for (var i = 2 + outerWindow; i < windowFrom; i++) {
    leftGap.push(i);
  }
  rightGap = new Array();
  for (var i = windowTo + 1; i < totalPages - outerWindow; i++) {
    rightGap.push(i);
  }
  if (leftGap.last - leftGap.first > 1) {
    visible.without(leftGap);
  }
  if (rightGap.last - leftGap.first > 1) {
    visible.without(rightGap);
  }
  return visible;
}

function cutZero(f) {
  var s = f.toString();
  while (s.match(/\.(.)*0$/)) {
    s = s.substring(0, s.length-2);
  }
  return s;
}
