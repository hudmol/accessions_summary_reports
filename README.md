accessions_summary_reports
==========================

An ArchivesSpace plugin that provides summary reports on Accessions.

This plugin was developed for the National Library of Australia by Hudson Molonglo Pty Ltd.


# Getting Started

Download the latest release from the Releases tab in Github:

    https://github.com/hudmol/accessions_summary_reports/releases

Unzip the release in the plugins directory of your ArchivesSpace:

    $ cd /path/to/archivesspace/plugins
    $ unzip accessions_summary_reports-vX.X.zip

Enable the plugin by editing the file in `config/config.rb`:

      AppConfig[:plugins] = ['some_plugin', 'accessions_summary_reports']

Make sure you uncomment this line (i.e., remove the leading '#' if present)

Then restart ArchivesSpace, see:

    https://github.com/archivesspace/archivesspace/blob/master/README.md

For more information about plugins see:

    https://github.com/archivesspace/archivesspace/blob/master/plugins/README.md


# How it Works

The plugin presents an item in the repository plugin menu.
After selecting 'Accession Summary Reports' you will be presented with a form.
Enter a start date, an end date and select a records type.
Click 'Run Report' and the results will display.

When you run a report, the frontend sends a request to the backend which runs SQL,
specified using the sequel syntax used by ArchivesSpace. See:

    backend/controllers/accessions_summary_reports.rb

Note that the 'received' report assumes the user_defined.boolean_1 field is used to
specify new accessions. To this end the plugin overrides the label for this field, see:

    frontend/locales/en.yml

Enjoy!
