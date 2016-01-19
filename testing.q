/ Matching Engine for HKEx
/ Test cases
/ Last Modified: Jan 20, 2015
/ Created by: Raymond Sak, Damian Dutkiewicz

/ import matching.q
\l /Users/Raymond/Projects/hkex-matching-engine-with-kdb/matching.q

/ Prepare data for testing
bidbook:0#bidbook;
askbook:0#askbook;
tradebook:0#tradebook;
rejectedbook:0#rejectedbook;
input:`time xasc CreateData 10000;
`bidbook upsert(select [50] from input where side=`bid);
`sym xasc `price xdesc `time xasc `orderID xkey `bidbook;
`askbook upsert(select [50] from input where side=`offer);
`sym`price`time xasc `orderID xkey `askbook;

/ Test case 1: Incoming order:: buy limit order, price: > top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(111111111;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]+1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the order is inserted into the rejected book, and no trades take places
select from rejectedbook
select from tradebook where sym=`GOOG

/ Test case 2: Incoming order:: buy limit order, price: < top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(222222222;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]-1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: order get inserted into the bidbook, and no trades take places
select from bidbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 3: Incoming order:: buy limit order, price: = top of askbook, quantity: < quantity of top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(333333333;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];askbook[GetTopOfBookOrderID[`GOOG;`offer]][`quantity]-1); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the incoming order get fully executed, the top of the askbook order quantity gets updated (left with a size of 1)
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 4: Incoming order:: buy limit order, price: = top of askbook, quantity: = quantity of top of askbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(444444444;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];askbook[GetTopOfBookOrderID[`GOOG;`offer]][`quantity]); / offfer = ask
MatchOrder[testorder];
/ Expected Result: both the incoming order and the top of the askbook order gets fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 5: Incoming order:: buy limit order, price: = top of askbook, quantity: > quantity of top of askbook
/ there are more orders with the same price as the incoming order price
testorder:`orderID`time`sym`side`orderType`price`quantity!(555555555;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];askbook[GetTopOfBookOrderID[`GOOG;`offer]][`quantity]+10); / offfer = ask
`askbook insert (100000000;09:04:59:000;`GOOG;`offer;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];3);
`askbook insert (200000000;09:06:59:000;`GOOG;`offer;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];4);
`askbook insert (300000000;09:08:59:000;`GOOG;`offer;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];3);
askbook:`sym`price`time xasc `orderID xkey askbook;
MatchOrder[testorder];
/ Expected Result: the incoming order get fully executed and multiple order from the top of the askbook gets executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 6: Incoming order:: buy limit order, price: = top of askbook, quantity: > quantity of top of askbook
/ there are no more orders with the same price as the incoming order price
`askbook insert (400000000;09:00:00:001;`GOOG;`offer;`limit;(askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]+bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price])%2;10);
askbook:`sym`price`time xasc `orderID xkey askbook;
testorder:`orderID`time`sym`side`orderType`price`quantity!(666666666;09:40:00.000;`GOOG;`bid;`limit;askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price];askbook[GetTopOfBookOrderID[`GOOG;`offer]][`quantity]+1); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the incoming order get partially executed (left with a size of 1) and the top of the askbook order gets fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Clean the books before you execute another test cases
bidbook:0#bidbook;
askbook:0#askbook;
tradebook:0#tradebook;
rejectedbook:0#rejectedbook;
`bidbook upsert(select [50] from input where side=`bid);
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
`askbook upsert(select [50] from input where side=`offer);
askbook:`sym`price`time xasc `orderID xkey askbook;

/ Test case 7: Incoming order:: ask limit order, price: < top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(111111111;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price]-1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the order is inserted into the rejected book, and no trades take places
select from rejectedbook
select from tradebook where sym=`GOOG

/ Test case 8: Incoming order:: ask limit order, price: > top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(222222222;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price]+1;123); / offfer = ask
MatchOrder[testorder];
/ Expected Result: order get inserted into the askbook, and no trades take places
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 9: Incoming order:: ask limit order, price: = top of bidbook, quantity: < quantity of top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(333333333;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]-1); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the incoming order get fully executed, the top of the bidbook order quantity gets updated (left with a size of 1)
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 10: Incoming order:: ask limit order, price: = top of bidbook, quantity: = quantity of top of bidbook
testorder:`orderID`time`sym`side`orderType`price`quantity!(444444444;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]); / offfer = ask
MatchOrder[testorder];
/ Expected Result: both the incoming order and the top of the askbook order gets fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 11: Incoming order:: ask limit order, price: = top of bidbook, quantity: > quantity of top of bidbook
/ there are more orders with the same price as the incoming order price
testorder:`orderID`time`sym`side`orderType`price`quantity!(555555555;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]+10); / offfer = ask
`bidbook insert (100000000;09:04:59:000;`GOOG;`bid;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];3);
`bidbook insert (200000000;09:06:59:000;`GOOG;`bid;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];4);
`bidbook insert (300000000;09:08:59:000;`GOOG;`bid;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];3);
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
MatchOrder[testorder];
/ Expected Result: the incoming order get fully executed and multiple order from the top of the bidbook gets executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Test case 12: Incoming order:: ask limit order, price: = top of bidbook, quantity: > quantity of top of bidbook
/ there are no more orders with the same price as the incoming order price
`bidbook insert (400000000;09:00:00:001;`GOOG;`bid;`limit;(askbook[GetTopOfBookOrderID[`GOOG;`offer]][`price]+bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price])%2;10);
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
testorder:`orderID`time`sym`side`orderType`price`quantity!(666666666;09:40:00.000;`GOOG;`offer;`limit;bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`price];bidbook[GetTopOfBookOrderID[`GOOG;`bid]][`quantity]+1); / offfer = ask
MatchOrder[testorder];
/ Expected Result: the incoming order get partially executed (left with a size of 1) and the top of the bidbook order gets fully executed
select from bidbook where sym=`GOOG, orderType=`limit
select from askbook where sym=`GOOG, orderType=`limit
select from tradebook where sym=`GOOG

/ Clean the books
bidbook:0#bidbook;
askbook:0#askbook;
tradebook:0#tradebook;
rejectedbook:0#rejectedbook;
`bidbook upsert(select [50] from input where side=`bid);
bidbook:`sym xasc `price xdesc `time xasc `orderID xkey bidbook;
`askbook upsert(select [50] from input where side=`offer);
askbook:`sym`price`time xasc `orderID xkey askbook;

/ Testing for GetNominalPrice

GetNominalPrice[`GOOG]
