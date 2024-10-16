Feature: Event Search
    Background: Initial setup
        Given "agenda"
        """
            [
                {"name": "sports", "_id": "sports", "is_enabled": true},
                {"name": "finance", "_id": "finance", "is_enabled": true},
                {"name": "entertainment", "_id": "entertainment", "is_enabled": true}
            ]
        """
        And "events"
            """
            [
                {
                    "guid": "event_123",
                    "unique_id": "123",
                    "unique_name": "name",
                    "recurrence_id": "recur1",
                    "state": "ingested",
                    "ingest_provider": "5923b82f1d41c858e1a5b0ce",
                    "name": "event 123",
                    "slugline": "test1 slugline",
                    "definition_short": "short value",
                    "definition_long": "long value",
                    "reference": "2020/00195696",
                    "dates": {
                        "start": "2016-01-02T00:00:00+0000",
                        "end": "2016-01-03T00:00:00+0000"
                    },
                    "subject": [{"qcode": "test qcode 1", "name": "test name"}],
                    "location": [{"qcode": "test qcode", "name": "test name"}],
                    "calendars": [
                        {"qcode": "finance", "name": "finance"},
                        {"qcode": "sports", "name": "sports"}
                    ],
                    "anpa_category": [
                        {"name": "Overseas Sport", "qcode": "s"}
                    ]
                },
                {
                    "guid": "event_456",
                    "unique_id": "456",
                    "unique_name": "name",
                    "state": "draft",
                    "name": "event 456",
                    "slugline": "test2 slugline",
                    "definition_short": "short value",
                    "definition_long": "long value",
                    "reference": "2020/00195697",
                    "dates": {
                        "start": "2016-01-02T00:00:00+0000",
                        "end": "2016-01-03T00:00:00+0000"
                    },
                    "subject": [{"qcode": "test qcode 2", "name": "test name", "translations": {"name": {"nl": "NL TEST"}}}],
                    "location": [{"qcode": "test qcode", "name": "test name"}],
                    "calendars": [
                        {"qcode": "entertainment", "name": "entertainment"}
                    ],
                    "anpa_category": [
                        {"name": "International News", "qcode": "i"}
                    ],
                    "place": [
                        {
                            "group": "Rest Of World",
                            "name": "ASIA",
                            "state": "",
                            "qcode": "ASIA",
                            "world_region": "Asia",
                            "country": ""
                        }
                    ],
                    "priority": 2
                },
                {
                    "guid": "event_786",
                    "unique_id": "786",
                    "unique_name": "name",
                    "name": "event 786",
                    "state": "published",
                    "pubstatus": "usable",
                    "slugline": "test3 slugline",
                    "definition_short": "short value",
                    "definition_long": "long value",
                    "reference": "2020/00195698",
                    "language": "fr-CA",
                    "dates": {
                        "start": "2016-01-02T00:00:00+0000",
                        "end": "2016-01-03T00:00:00+0000"
                    },
                    "subject": [{"qcode": "test qcode 2", "name": "test name"}],
                    "lock_session": "ident1",
                    "priority": 7
                }
            ]
            """
        And "planning"
        """
        [
            {
                "guid": "planning_1",
                "item_class": "item class value",
                "headline": "test headline",
                "slugline": "slug123",
                "planning_date": "2016-01-02T12:00:00+0000",
                "agendas": ["sports"]
            }
        ]
        """

    @auth
    Scenario: Only retrieve events when using repo=events
        When we get "/events_planning_search?repo=events"
        Then we get list with 0 items
        When we get "/events_planning_search?repo=events&only_future=false"
        Then we get list with 3 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"},
            {"_id": "event_786"}
        ]}
        """

    @auth
    Scenario: Search by common parameters
        When we get "/events_planning_search?repo=events&only_future=false&item_ids=event_123,event_786"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&name=event%20786"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&full_text=test2"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&anpa_category=s,i"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&subject=test%20qcode%202"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_456"},
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&posted=true"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&place=ASIA"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&language=fr-CA"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&lock_state=locked"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&lock_state=unlocked"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&recurrence_id=recur1"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_123"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&state=draft,ingested"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&priority=2,7"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_456"},
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&priority=1"
        Then we get list with 0 items

        When we get "/events_planning_search?repo=events&only_future=false&full_text=test name"
        Then we get list with 3 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"},
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&full_text=TEST NAME"
        Then we get list with 3 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"},
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&full_text=Test Name"
        Then we get list with 3 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"},
            {"_id": "event_786"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&full_text=NL TEST"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&full_text=nl test"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_456"}
        ]}
        """

    @auth
    Scenario: Search by event specific parameters
        When we get "/events_planning_search?repo=events&only_future=false&slugline=test1%20OR%20test2"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&reference=2020%2F00195696"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_123"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&source=5923b82f1d41c858e1a5b0ce"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_123"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&location=test%20qcode"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&calendars=finance,entertainment"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "event_123"},
            {"_id": "event_456"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&no_calendar_assigned=true"
        Then we get list with 1 items
        """
        {"_items": [
            {"_id": "event_786"}
        ]}
        """

    @auth
    Scenario: Users can only see their events without the planning_global_filters privilege
        Given "events"
        """
        [{
            "guid": "user_1_event_1",
            "name": "event1 for user 1",
            "dates": {"start": "2016-01-02T00:00:00+0000", "end": "2016-01-03T00:00:00+0000"},
            "original_creator": "user_1"
        }, {
            "guid": "user_1_event_2",
            "name": "event2 for user 1",
            "dates": {"start": "2016-01-02T00:00:00+0000", "end": "2016-01-03T00:00:00+0000"},
            "original_creator": "user_1"
        }, {
            "guid": "user_2_event_1",
            "name": "event1 for user 2",
            "dates": {"start": "2016-01-02T00:00:00+0000", "end": "2016-01-03T00:00:00+0000"},
            "original_creator": "#CONTEXT_USER_ID#"
        }, {
            "guid": "user_2_event_2",
            "name": "event2 for user 2",
            "dates": {"start": "2016-01-02T00:00:00+0000", "end": "2016-01-03T00:00:00+0000"},
            "original_creator": "#CONTEXT_USER_ID#"
        }]
        """
        When we patch "/users/#CONTEXT_USER_ID#"
        """
        {"user_type": "user", "privileges": {"planning_global_filters": 0, "users": 1}}
        """
        Then we get OK response
        When we get "/events_planning_search?repo=events&only_future=false"
        Then we get list with 2 items
        """
        {"_items": [
            {"_id": "user_2_event_1"},
            {"_id": "user_2_event_2"}
        ]}
        """
        When we patch "/users/#CONTEXT_USER_ID#"
        """
        {"user_type": "user", "privileges": {"planning_global_filters": 1, "users": 1}}
        """
        Then we get OK response
        When we get "/events_planning_search?repo=events&only_future=false"
        Then we get list with 4 items
        """
        {"_items": [
            {"_id": "user_1_event_1"},
            {"_id": "user_1_event_2"},
            {"_id": "user_2_event_1"},
            {"_id": "user_2_event_2"}
        ]}
        """

    @auth
    Scenario: Filter by date using America/Toronto timezone
        Given "events"
        """
        [{
            "guid": "all_day_multi",
            "name": "all day event multiday",
            "dates": {"start": "2024-07-14T00:00:00+0000", "end": "2024-07-16T00:00:00+0000", "all_day": true}
        }, {
            "guid": "all_day_single",
            "name": "all day single day",
            "dates": {"start": "2024-07-15T00:00:00+0000", "end": "2024-07-15T00:00:00+0000", "all_day": true}
        }, {
            "guid": "no_end_time_multi",
            "name": "no end time multiday",
            "dates": {"start": "2024-07-13T10:00:00+0000", "end": "2024-07-15T00:00:00+0000", "no_end_time": true}
        }, {
            "guid": "no_end_time_single",
            "name": "no end time single day",
            "dates": {"start": "2024-07-15T10:00:00+0000", "end": "2024-07-15T10:00:00+0000", "no_end_time": true}
        }, {
            "guid": "matching",
            "name": "regular",
            "dates": {"start": "2024-07-15T10:00:00+0000", "end": "2024-07-16T00:00:00+0000"}
        },
        {
            "guid": "not matching",
            "name": "not matching",
            "dates": {"start": "2024-07-01T10:00:00+0000", "end": "2024-07-02T00:00:00+0000"}
        }
        ]
        """
        When we get "/events_planning_search?repo=events&only_future=false&time_zone=America/Toronto&start_date=2024-07-15T04:00:00"
        Then we get list with 5 items
        """
        {"_items": [
            {"guid": "all_day_multi"},
            {"guid": "all_day_single"},
            {"guid": "no_end_time_multi"},
            {"guid": "no_end_time_single"},
            {"guid": "matching"}
        ]}
        """
        When we get "/events_planning_search?repo=events&only_future=false&time_zone=America/Toronto&start_date=2024-07-16T04:00:00"
        Then we get list with 1 items
        """
        {"_items": [
            {"guid": "all_day_multi"}
        ]}
        """
