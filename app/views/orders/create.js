alert("<%= @order.email %>")

$("#paypal_submit").click( function(){
  $("#order_submit").click();
})

$("#order_submit").click( function(){
  alert('sth');
})


