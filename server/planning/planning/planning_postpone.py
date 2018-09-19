# -*- coding: utf-8; -*-
#
# This file is part of Superdesk.
#
# Copyright 2013, 2014 Sourcefabric z.u. and contributors.
#
# For the full copyright and license information, please see the
# AUTHORS and LICENSE files distributed with this source code, or
# at https://www.sourcefabric.org/superdesk/license

from superdesk.services import BaseService
from superdesk.notification import push_notification
from apps.archive.common import get_user, get_auth
from eve.utils import config
from copy import deepcopy
from .planning import PlanningResource, planning_schema
from planning.common import WORKFLOW_STATE, ITEM_STATE, get_coverage_type_name
from superdesk import get_resource_service
from planning.planning_notifications import PlanningNotifications

planning_postpone_schema = deepcopy(planning_schema)
planning_postpone_schema['reason'] = {
    'type': 'string',
    'nullable': True
}


class PlanningPostponeResource(PlanningResource):
    url = 'planning/postpone'
    resource_title = endpoint_name = 'planning_postpone'

    datasource = {'source': 'planning'}
    resource_methods = []
    item_methods = ['PATCH']
    privileges = {'PATCH': 'planning_planning_management'}
    internal_resource = True

    schema = planning_postpone_schema


class PlanningPostponeService(BaseService):
    def update(self, id, updates, original):
        self._postpone_plan(updates, original)
        updates['coverages'] = deepcopy(original.get('coverages'))
        coverages = updates.get('coverages') or []

        for coverage in coverages:
            self._postpone_coverage(updates, coverage)

        reason = updates.get('reason', None)
        if 'reason' in updates:
            del updates['reason']

        item = self.backend.update(self.datasource, id, updates, original)

        user = get_user(required=True).get(config.ID_FIELD, '')
        session = get_auth().get(config.ID_FIELD, '')

        push_notification(
            'planning:postponed',
            item=str(original[config.ID_FIELD]),
            user=str(user),
            session=str(session),
            reason=reason
        )

        return item

    def _postpone_plan(self, updates, original):
        ednote = '''------------------------------------------------------------
Event Postponed
'''
        if updates.get('reason', None) is not None:
            ednote += 'Reason: {}\n'.format(updates['reason'])

        if len(original.get('ednote') or '') > 0:
            updates['ednote'] = original['ednote'] + '\n\n' + ednote
        else:
            updates['ednote'] = ednote

        updates[ITEM_STATE] = WORKFLOW_STATE.POSTPONED

    def _postpone_coverage(self, updates, coverage):
        note = '''------------------------------------------------------------
Event has been postponed
'''
        if updates.get('reason', None) is not None:
            note += 'Reason: {}\n'.format(updates['reason'])

        if not coverage.get('planning'):
            coverage['planning'] = {}

        if len(coverage['planning'].get('internal_note') or '') > 0:
            coverage['planning']['internal_note'] += '\n\n' + note
        else:
            coverage['planning']['internal_note'] = note

        if len(coverage['planning'].get('ednote') or '') > 0:
            coverage['planning']['ednote'] += '\n\n' + note
        else:
            coverage['planning']['ednote'] = note

        assigned_to = coverage.get('assigned_to')
        if assigned_to:
            assignment_service = get_resource_service('assignments')
            assignment = assignment_service.find_one(req=None, _id=assigned_to.get('assignment_id'))
            slugline = assignment.get('planning').get('slugline', '')
            coverage_type = assignment.get('planning').get('g2_content_type', '')
            PlanningNotifications().notify_assignment(coverage_status=assignment.get('assigned_to').get('state'),
                                                      target_user=assignment.get('assigned_to').get('user'),
                                                      target_desk=assignment.get('assigned_to').get(
                                                          'desk') if not assignment.get('assigned_to').get(
                                                          'user') else None,
                                                      message='The event associated with {{coverage_type}} coverage '
                                                              '\"{{slugline}}\" has been marked as postponed',
                                                      slugline=slugline,
                                                      coverage_type=get_coverage_type_name(coverage_type))
