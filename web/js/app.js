/* AudioGuard back-office - jQuery 1.6.2 */
$(function () {

    $('#check-all').click(function () {
        $('#hits input[name="ids[]"]').attr('checked', this.checked);
    });

    $('#bulk-go').click(function () {
        var action = $('#bulk-action').val(),
            n = $('#hits input[name="ids[]"]:checked').length;
        if (!action) { alert('Bitte Aktion wählen.'); return; }
        if (!n)      { alert('Keine Treffer ausgewählt.'); return; }
        if (action === 'approve' && !confirm(n + ' Treffer freigeben und Notices erstellen?\n\nBitte nur bei eindeutigem Treffer!')) {
            return;
        }
        $('#bulk-msg').text('...');
        $.ajax({
            url: 'ajax/takedown.php',
            type: 'POST',
            dataType: 'json',
            data: $('#hits-form').serialize(),
            success: function (res) {
                $('#bulk-msg').text(res.msg).toggleClass('error', !res.ok);
                if (res.ok) {
                    // TODO: update rows in place instead of reload
                    setTimeout(function () { location.reload(); }, 800);
                }
            },
            error: function (xhr) {
                // 'approve' currently ends here (PHP fatal -> no JSON)
                $('#bulk-msg').text('Serverfehler (' + xhr.status + ')').addClass('error');
            }
        });
    });

    // TODO: trend chart (#chart-trend) - data endpoint ajax/stats.php not written
});
