document.observe('dom:loaded', function() {
  var truncated_tags = $$('.tag_group .truncated');

  truncated_tags.each(function(link) {
    var span   = link.up('span');
    var height = span.getHeight();
    var offset = span.positionedOffset();

    var popup = new Element('span').update(link.readAttribute('title'));
    popup.setStyle({
      'position': 'absolute',
      'top': (offset.top + height) + 'px',
      'left': (offset.left - 4) + 'px',
      'border': '1px solid #000000',
      'padding': '0 3px',
      'backgroundColor': 'lightyellow'
    });
    span.insert(popup);
    popup.hide();

    link.observe('mouseover', popup.show.bindAsEventListener(popup));
    link.observe('mouseout', popup.hide.bindAsEventListener(popup));
  });
});