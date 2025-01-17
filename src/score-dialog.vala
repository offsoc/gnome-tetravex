/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-

   This file is part of GNOME Tetravex.

   Copyright (C) 2010-2013 Robert Ancell
   Copyright (C) 2019 Arnaud Bonatti

   GNOME Tetravex is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 2 of the License, or
   (at your option) any later version.

   GNOME Tetravex is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with this GNOME Tetravex.  If not, see <https://www.gnu.org/licenses/>.
*/

using Gtk;

private class ScoreDialog : Dialog
{
    private History history;
    private HistoryEntry? selected_entry = null;
    private Gtk.ListStore size_model;
    private Gtk.ListStore score_model;
    private ComboBox size_combo;
    private TreeView scores;

    internal ScoreDialog (History history, uint8 size, HistoryEntry? selected_entry = null)
    {
        Object (use_header_bar: /* true */ 1);

        get_style_context ().add_class ("score-dialog");

        this.history = history;
        history.entry_added.connect (entry_added_cb);
        this.selected_entry = selected_entry;

        set_size_request (210, 300);

        size_model = new Gtk.ListStore (2, typeof (string), typeof (int));

        size_combo = new ComboBox ();
        size_combo.changed.connect (size_changed_cb);
        size_combo.model = size_model;
        CellRendererText renderer = new CellRendererText ();
        size_combo.pack_start (renderer, true);
        size_combo.add_attribute (renderer, "text", 0);
        size_combo.width_request = 90;
        size_combo.show ();
        ((HeaderBar) get_header_bar ()).set_custom_title (size_combo);

        ScrolledWindow scroll = new ScrolledWindow (null, null);
        scroll.shadow_type = ShadowType.ETCHED_IN;
        scroll.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
        scroll.set_shadow_type (ShadowType.NONE);
        scroll.show ();

        Box content_area = get_content_area ();
        content_area.border_width = 0;
        content_area.pack_start (scroll, true, true, 0);

        score_model = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (int));

        scores = new TreeView ();
        renderer = new CellRendererText ();
        /* Translators: in the Scores dialog, in the scores list, label of the column displaying when games were played */
        scores.insert_column_with_attributes (-1, _("Date"), renderer, "text", 0, "weight", 2);
        renderer = new CellRendererText ();
        renderer.xalign = 1.0f;
        /* Translators: in the Scores dialog, in the scores list, label of the column displaying the duration of played games */
        scores.insert_column_with_attributes (-1, _("Time"), renderer, "text", 1, "weight", 2);
        scores.model = score_model;
        scores.show ();
        scroll.add (scores);

        foreach (HistoryEntry entry in history.entries)
            entry_added_cb (entry);

        TreeIter iter;
        if (get_size_iter (size, out iter))
            size_combo.set_active_iter (iter);
    }

    private void set_size (uint8 size)
    {
        score_model.clear ();

        foreach (HistoryEntry entry in history.entries)
        {
            if (entry.size != size)
                continue;

            /* "the preferred date representation for the current locale without the time" */
            string date_label = entry.date.format ("%x");

            string time_label = HistoryEntry.get_duration_string (entry);

            int weight = Pango.Weight.NORMAL;
            if (entry == selected_entry)
                weight = Pango.Weight.BOLD;

            TreeIter iter;
            score_model.append (out iter);
            score_model.@set (iter, 0, date_label, 1, time_label, 2, weight);

            if (entry == selected_entry)
            {
                TreeIter piter = iter;
                if (score_model.iter_previous (ref piter))
                {
                    TreeIter ppiter = piter;
                    if (score_model.iter_previous (ref ppiter))
                        piter = ppiter;
                }
                else
                    piter = iter;
                scores.scroll_to_cell (score_model.get_path (piter), null, false, 0, 0);
            }
        }
    }

    private void size_changed_cb (ComboBox combo)
    {
        TreeIter iter;
        if (!combo.get_active_iter (out iter))
            return;

        int size;
        combo.model.@get (iter, 1, out size);
        set_size ((uint8) size);
    }

    private void entry_added_cb (HistoryEntry entry)
    {
        /* Ignore if already have an entry for this */
        TreeIter iter;
        if (!get_size_iter (entry.size, out iter))
        {
            /* Translators: this string creates the options of the combobox seen in the Scores dialog; the %u are replaced by the board size; it allows to choose for which board size you want to see the scores, for example between "2 × 2" and "3 × 3" */
            string label = _("%u × %u").printf (entry.size, entry.size);

            size_model.append (out iter);
            size_model.@set (iter, 0, label, 1, entry.size);

            /* Select this entry if don't have any */
            if (size_combo.get_active () == -1)
                size_combo.set_active_iter (iter);

            /* Select this entry if the same category as the selected one */
            if (selected_entry != null && entry.size == ((!) selected_entry).size)
                size_combo.set_active_iter (iter);
        }
    }

    private bool get_size_iter (uint8 requested_size, out TreeIter iter)
    {
        if (size_model.get_iter_first (out iter))
        {
            do
            {
                int size;
                size_model.@get (iter, 1, out size, -1);
                if (size == requested_size)
                    return true;
            }
            while (size_model.iter_next (ref iter));
        }
        return false;
    }
}
