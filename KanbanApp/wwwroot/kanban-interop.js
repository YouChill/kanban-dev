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
    }
};
