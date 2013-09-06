function buyViaPayPal(order_id, theme_id){
  var buyViaPayPal = $('<form>', {
    'action': 'https://www.paypal.com/cgi-bin/webscr',
    'target': '_top'
  }).append($('<input>', {
      'name': 'cmd',
      'value': '_s-xclick',
      'type': 'hidden'
    }).append($('<input>', {
        'name': 'hosted_button_id',
        'value': 'XU8QNUFFABBUQ',
        'type': 'hidden'
      }).append($('<input>', {
          'name': 'item_name',
          'value': 'Order: ' + order_id + ' - theme #' + theme_id + ' development.',
          'type': 'hidden'
        }))));
  buyViaPayPal.submit();
}
