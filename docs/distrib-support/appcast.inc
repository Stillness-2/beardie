<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>{{ site.github.project_title }}</title>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        {% for release in site.github.releases limit:1 %}
            {% unless release.draft %}
                {% unless release.prerelease and include.release_only %}
                    <item>
                        <title>{{ release.name }}</title>
                        <sparkle:releaseNotesLink>
                            {{ include.release_notes | absolute_url }}
                        </sparkle:releaseNotesLink>
                        <pubDate>{{ release.published_at | date_to_rfc822 }}</pubDate>
                        {% for asset in release.assets limit:1 %}
                            {% assign build_nums = release.tag_name | remove_first:'v' | split:'.' %}
                            {% if build_nums.size == 5 %}
                                {% assign version = build_nums[3] %}
                                {% if build_nums[4] == "Release" %}
                                    {% assign short_version = build_nums | pop | pop | join: "." %}
                                {% else %}
                                    {% assign short_version = build_nums | pop | pop | join: "." | append: " " | append: build_nums[4] %}
                                {% endif %}
                            {% else %}
                                {% assign version = release.tag_name | remove_first:'v' %}
                            {% endif %}
                            <sparkle:minimumSystemVersion>10.15</sparkle:minimumSystemVersion>
                            <enclosure
                                url="{{ asset.browser_download_url }}"
                                sparkle:version="{{ version }}"
                                {% if short_version %}sparkle:shortVersionString="{{ short_version }}"{% endif %}
                                length="{{ asset.size }}"
                                type="application/octet-stream" />
                        {% endfor %}
                    </item>
                {% endunless %}
            {% endunless %}
        {% endfor %}
    </channel>
</rss>
