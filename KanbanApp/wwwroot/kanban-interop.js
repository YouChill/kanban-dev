window.kanbanInterop = {
    scrollIntoView: function (selector) {
        const el = document.querySelector(selector);
        if (el) {
            el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        }
    },
    scrollToLastCard: function (columnId) {
        const zone = document.querySelector('[identifier="' + columnId + '"]');
        if (zone) {
            const cards = zone.querySelectorAll('.task-card');
            if (cards.length > 0) {
                cards[cards.length - 1].scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }
        }
    },
    focusFirstAddTask: function () {
        const btn = document.querySelector('.kanban-column__add-task');
        if (btn) {
            btn.click();
        }
    },
    downloadFile: function (fileName, content, mimeType) {
        var blob = new Blob([content], { type: mimeType });
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = fileName;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }
};
