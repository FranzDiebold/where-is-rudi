"""Send Slack message to gather information.
"""

import os
import slack


DEFAULT_DOG_NAME = 'Rudi'


SLACK_TOKEN = os.environ['SLACK_API_TOKEN']
SLACK_CLIENT = slack.WebClient(
    token=SLACK_TOKEN,
    timeout=10,
)

USER_ID_TO_GATHER_INFORMATION_FROM = os.environ['USER_ID']
DOG_NAME = os.environ.get('DOG_NAME', DEFAULT_DOG_NAME)


def gather_information() -> None:
    """Triggered from a message on a Cloud Pub/Sub topic."""
    print('Gathering information...')

    SLACK_CLIENT.chat_postMessage(
        channel=USER_ID_TO_GATHER_INFORMATION_FROM,
        blocks=[
            {
                'type': 'section',
                'text': {
                    'type': 'mrkdwn',
                    'text': f'Good Morning! :sunny:\nWill you bring {DOG_NAME} to work today?'
                }
            },
            {
                'type': 'actions',
                'elements': [
                    {
                        'type': 'button',
                        'text': {
                            'type': 'plain_text',
                            'text': ':dog: Yes',
                            'emoji': True
                        },
                        'value': 'response_yes'
                    },
                    {
                        'type': 'button',
                        'text': {
                            'type': 'plain_text',
                            'text': ':no_entry_sign: No',
                            'emoji': True
                        },
                        'value': 'response_no'
                    }
                ]
            }
        ]
    )
    print('Done!')
