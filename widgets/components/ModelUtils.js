.pragma library

function updateListModel(model, newItems, idKey, fieldList) {
    if (!model || !newItems) return;
    idKey = idKey || "address";

    var existingIds = {};
    for (var i = 0; i < model.count; i++) {
        var item = model.get(i);
        if (item && item[idKey] !== undefined) {
            existingIds[item[idKey]] = i;
        }
    }

    var newIds = {};
    for (var j = 0; j < newItems.length; j++) {
        var newItem = newItems[j];
        if (!newItem || newItem[idKey] === undefined) continue;
        var itemId = newItem[idKey];
        newIds[itemId] = true;

        if (itemId in existingIds) {
            var idx = existingIds[itemId];
            if (fieldList && fieldList.length > 0) {
                for (var f = 0; f < fieldList.length; f++) {
                    var key = fieldList[f];
                    var val = newItem[key];
                    if (val === null || val === undefined) val = "";
                    model.setProperty(idx, key, val);
                }
            } else {
                for (var prop in newItem) {
                    var v = newItem[prop];
                    if (v === null || v === undefined) v = "";
                    model.setProperty(idx, prop, v);
                }
            }
        } else {
            model.append(newItem);
        }
    }

    for (var k = model.count - 1; k >= 0; k--) {
        var curr = model.get(k);
        if (curr && curr[idKey] !== undefined && !(curr[idKey] in newIds)) {
            model.remove(k);
        }
    }
}

function drawRRect(ctx, x, y, w, h, r) {
    if (r > w / 2) r = w / 2;
    if (r > h / 2) r = h / 2;
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.arcTo(x + w, y, x + w, y + r, r);
    ctx.lineTo(x + w, y + h - r);
    ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
    ctx.lineTo(x + r, y + h);
    ctx.arcTo(x, y + h, x, y + h - r, r);
    ctx.lineTo(x, y + r);
    ctx.arcTo(x, y, x + r, y, r);
    ctx.closePath();
}

