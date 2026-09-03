export const meta = {
  name: 'GAW Actions end-to-end proof',
  description: 'Runs one governed no-tool inference through GitHub Actions.',
  model: 'gpt-4o-mini',
  interface: {
    schemaVersion: 1,
    inputs: {
      type: 'object',
      properties: {},
      additionalProperties: false,
    },
    outputs: {},
  },
  deployment: {
    schemaVersion: 1,
    modes: [
      {
        id: 'local',
        label: 'Run locally',
        target: { kind: 'repository' },
        runtime: { placement: 'local', provider: 'gaw-local' },
        trigger: { kind: 'manual' },
        inputs: { authority: 'caller' },
      },
      {
        id: 'actions',
        label: 'Run from GitHub Actions',
        target: { kind: 'repository' },
        runtime: { placement: 'cloud', provider: 'github-actions' },
        trigger: { kind: 'manual' },
        inputs: { authority: 'caller' },
      },
    ],
  },
  phases: [
    { title: 'Inference', detail: 'Verify the deployed workflow can execute one governed agent call.' },
  ],
}

phase('Inference')
const response = await agent(
  'Reply with exactly GAW_ACTIONS_OK and no other text.',
  {
    label: 'GAW Actions end-to-end proof',
    phase: 'Inference',
    model: 'gpt-4o-mini',
    budget: { maxTokens: 20000 },
  },
)

return { response }
