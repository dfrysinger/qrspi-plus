// User-owned large workflow used by the Nexus video QA walkthrough.
export const meta = {
  "name": "Video QA deep review",
  "description": "Large governed pull-request review used to verify Nexus Agentic Apps.",
  "model": "gpt-5.4",
  "agentCount": "dynamic",
  "interface": {
    "schemaVersion": 1,
    "inputs": {
      "type": "object",
      "additionalProperties": false,
      "required": [
        "schemaVersion",
        "execution",
        "request",
        "actor",
        "pr",
        "reviews",
        "markerIndex",
        "promptBundle",
        "ownedResources",
        "git"
      ],
      "properties": {
        "schemaVersion": {
          "type": "integer",
          "enum": [
            2
          ]
        },
        "execution": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "generatedAt",
            "postingLogin",
            "workspace"
          ],
          "properties": {
            "generatedAt": {
              "type": "string",
              "minLength": 1
            },
            "postingLogin": {
              "type": "string",
              "minLength": 1
            },
            "workspace": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "resourceRole",
                "relativePath",
                "head",
                "tree"
              ],
              "properties": {
                "resourceRole": {
                  "type": "string",
                  "enum": [
                    "container"
                  ]
                },
                "relativePath": {
                  "type": "string",
                  "minLength": 1
                },
                "head": {
                  "type": "string",
                  "minLength": 40,
                  "maxLength": 40
                },
                "tree": {
                  "type": "string",
                  "minLength": 40,
                  "maxLength": 40
                }
              }
            }
          }
        },
        "request": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "dryRun",
            "serverUrl",
            "prUrl",
            "strategy"
          ],
          "properties": {
            "dryRun": {
              "type": "boolean"
            },
            "serverUrl": {
              "type": "string",
              "minLength": 1
            },
            "prUrl": {
              "type": "string",
              "minLength": 1
            },
            "strategy": {
              "type": "string",
              "enum": [
                "once",
                "automatic",
                "full"
              ]
            },
            "expectedHead": {
              "type": "string",
              "minLength": 40,
              "maxLength": 40
            }
          }
        },
        "actor": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "login"
          ],
          "properties": {
            "login": {
              "type": "string",
              "minLength": 1
            }
          }
        },
        "pr": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "base",
            "body",
            "head",
            "merged",
            "number",
            "owner",
            "ref",
            "repo",
            "state",
            "title"
          ],
          "properties": {
            "base": {
              "type": "string",
              "minLength": 40,
              "maxLength": 40
            },
            "body": {
              "type": "string"
            },
            "head": {
              "type": "string",
              "minLength": 40,
              "maxLength": 40
            },
            "merged": {
              "type": "boolean"
            },
            "number": {
              "type": "integer",
              "minimum": 1
            },
            "owner": {
              "type": "string",
              "minLength": 1
            },
            "ref": {
              "type": "string",
              "minLength": 1
            },
            "repo": {
              "type": "string",
              "minLength": 1
            },
            "state": {
              "type": "string",
              "minLength": 1
            },
            "title": {
              "type": "string"
            }
          }
        },
        "reviews": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "authorLogin",
              "body",
              "id",
              "submittedAt"
            ],
            "properties": {
              "authorLogin": {
                "type": "string",
                "minLength": 1
              },
              "body": {
                "type": "string"
              },
              "id": {
                "type": "integer",
                "minimum": 1
              },
              "submittedAt": {
                "type": [
                  "string",
                  "null"
                ]
              }
            }
          }
        },
        "markerIndex": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "bodyByteOffset",
              "reviewId",
              "reviewedHead"
            ],
            "properties": {
              "bodyByteOffset": {
                "type": "integer",
                "minimum": 0
              },
              "reviewId": {
                "type": "integer",
                "minimum": 1
              },
              "reviewedHead": {
                "type": "string",
                "minLength": 40,
                "maxLength": 40
              },
              "reviewedMergeBase": {
                "type": "string",
                "minLength": 40,
                "maxLength": 40
              }
            }
          }
        },
        "promptBundle": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "bundleDigest",
            "members",
            "schemaVersion",
            "workflowDigest"
          ],
          "properties": {
            "bundleDigest": {
              "type": "string",
              "minLength": 71,
              "maxLength": 71
            },
            "members": {
              "type": "array",
              "items": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "bytes",
                  "path",
                  "sha256"
                ],
                "properties": {
                  "bytes": {
                    "type": "integer",
                    "minimum": 0
                  },
                  "path": {
                    "type": "string",
                    "minLength": 1
                  },
                  "sha256": {
                    "type": "string",
                    "minLength": 71,
                    "maxLength": 71
                  }
                }
              }
            },
            "schemaVersion": {
              "type": "integer",
              "enum": [
                1
              ]
            },
            "workflowDigest": {
              "type": "string",
              "minLength": 71,
              "maxLength": 71
            }
          }
        },
        "ownedResources": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "identity",
            "identityDigest",
            "schemaVersion"
          ],
          "properties": {
            "identity": {
              "type": "object",
              "additionalProperties": false,
              "required": [
                "backend",
                "leaseId",
                "nonce",
                "resources",
                "runIdentity",
                "schemaVersion",
                "scratchRoot",
                "workflowDigest"
              ],
              "properties": {
                "backend": {
                  "type": "string",
                  "minLength": 1
                },
                "leaseId": {
                  "type": "string",
                  "minLength": 64,
                  "maxLength": 64
                },
                "nonce": {
                  "type": "string",
                  "minLength": 64,
                  "maxLength": 64
                },
                "resources": {
                  "type": "array",
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "path",
                      "role"
                    ],
                    "properties": {
                      "path": {
                        "type": "string",
                        "minLength": 1
                      },
                      "role": {
                        "type": "string",
                        "enum": [
                          "container",
                          "allocation-staging"
                        ]
                      }
                    }
                  }
                },
                "runIdentity": {
                  "type": "string",
                  "minLength": 1
                },
                "schemaVersion": {
                  "type": "integer",
                  "enum": [
                    1
                  ]
                },
                "scratchRoot": {
                  "type": "string",
                  "minLength": 1
                },
                "workflowDigest": {
                  "type": "string",
                  "minLength": 71,
                  "maxLength": 71
                }
              }
            },
            "identityDigest": {
              "type": "string",
              "minLength": 71,
              "maxLength": 71
            },
            "schemaVersion": {
              "type": "integer",
              "enum": [
                1
              ]
            }
          }
        },
        "git": {
          "type": "object",
          "additionalProperties": false,
          "required": [
            "anchorBase",
            "anchorDiff",
            "anchorHead",
            "currentChangedFiles",
            "currentMergeBase",
            "currentMergeBaseIsAncestorOfBase",
            "currentMergeBaseIsAncestorOfHead",
            "objectRetrievability",
            "reprojections"
          ],
          "properties": {
            "anchorBase": {
              "type": "string",
              "minLength": 40,
              "maxLength": 40
            },
            "anchorDiff": {
              "type": "string"
            },
            "anchorHead": {
              "type": "string",
              "minLength": 40,
              "maxLength": 40
            },
            "currentChangedFiles": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "currentMergeBase": {
              "type": "string",
              "minLength": 40,
              "maxLength": 40
            },
            "currentMergeBaseIsAncestorOfBase": {
              "type": "boolean"
            },
            "currentMergeBaseIsAncestorOfHead": {
              "type": "boolean"
            },
            "objectRetrievability": {
              "type": "object",
              "additionalProperties": {
                "type": "boolean"
              },
              "properties": {}
            },
            "reprojections": {
              "type": "array",
              "items": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "conflicted",
                  "currentHead",
                  "currentMergeBase",
                  "prevHead",
                  "priorMergeBase",
                  "structuralError",
                  "syntheticBase",
                  "windowDiff",
                  "windowFiles"
                ],
                "properties": {
                  "conflicted": {
                    "type": "boolean"
                  },
                  "currentHead": {
                    "type": "string",
                    "minLength": 40,
                    "maxLength": 40
                  },
                  "currentMergeBase": {
                    "type": "string",
                    "minLength": 40,
                    "maxLength": 40
                  },
                  "prevHead": {
                    "type": "string",
                    "minLength": 40,
                    "maxLength": 40
                  },
                  "priorMergeBase": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "structuralError": {
                    "type": "boolean"
                  },
                  "syntheticBase": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "windowDiff": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "windowFiles": {
                    "type": [
                      "array",
                      "null"
                    ],
                    "items": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "outputs": {
      "result": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "schemaVersion",
          "status",
          "reason",
          "post",
          "artifactIdentity",
          "artifacts"
        ],
        "properties": {
          "schemaVersion": {
            "type": "integer",
            "enum": [
              1
            ]
          },
          "status": {
            "type": "string",
            "enum": [
              "refuse",
              "skipped",
              "noop",
              "advance",
              "reviewed",
              "failed"
            ]
          },
          "reason": {
            "type": "string",
            "minLength": 1
          },
          "post": {
            "type": [
              "object",
              "null"
            ],
            "additionalProperties": false,
            "required": [
              "schemaVersion",
              "kind",
              "repository",
              "event",
              "reviewedHead",
              "reviewedMergeBase",
              "expectedBase",
              "expectedHead",
              "observation",
              "payload",
              "limits",
              "dryRun",
              "idempotencyKey",
              "preconditions"
            ],
            "properties": {
              "schemaVersion": {
                "type": "integer",
                "enum": [
                  1
                ]
              },
              "kind": {
                "type": "string",
                "enum": [
                  "conditional-pull-request-review"
                ]
              },
              "repository": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "owner",
                  "repo",
                  "number"
                ],
                "properties": {
                  "owner": {
                    "type": "string",
                    "minLength": 1
                  },
                  "repo": {
                    "type": "string",
                    "minLength": 1
                  },
                  "number": {
                    "type": "integer",
                    "minimum": 1
                  }
                }
              },
              "event": {
                "type": "string",
                "enum": [
                  "COMMENT"
                ]
              },
              "reviewedHead": {
                "type": "string",
                "minLength": 40,
                "maxLength": 40
              },
              "reviewedMergeBase": {
                "type": "string",
                "minLength": 40,
                "maxLength": 40
              },
              "expectedBase": {
                "type": "string",
                "minLength": 40,
                "maxLength": 40
              },
              "expectedHead": {
                "type": "string",
                "minLength": 40,
                "maxLength": 40
              },
              "observation": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "authorLogin",
                  "knownReviewIds",
                  "maxSubmittedAt",
                  "idempotencyMarker"
                ],
                "properties": {
                  "authorLogin": {
                    "type": "string",
                    "minLength": 1
                  },
                  "knownReviewIds": {
                    "type": "array",
                    "items": {
                      "type": "integer",
                      "minimum": 1
                    }
                  },
                  "maxSubmittedAt": {
                    "type": [
                      "string",
                      "null"
                    ]
                  },
                  "idempotencyMarker": {
                    "type": "string",
                    "minLength": 1
                  }
                }
              },
              "payload": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "body",
                  "event",
                  "commit_id"
                ],
                "properties": {
                  "body": {
                    "type": "string",
                    "minLength": 1
                  },
                  "event": {
                    "type": "string",
                    "enum": [
                      "COMMENT"
                    ]
                  },
                  "commit_id": {
                    "type": "string",
                    "minLength": 40,
                    "maxLength": 40
                  },
                  "comments": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "body",
                        "line",
                        "path",
                        "side"
                      ],
                      "properties": {
                        "body": {
                          "type": "string",
                          "minLength": 1
                        },
                        "line": {
                          "type": "integer",
                          "minimum": 1
                        },
                        "path": {
                          "type": "string",
                          "minLength": 1
                        },
                        "side": {
                          "type": "string",
                          "enum": [
                            "RIGHT"
                          ]
                        },
                        "start_line": {
                          "type": "integer",
                          "minimum": 1
                        },
                        "start_side": {
                          "type": "string",
                          "enum": [
                            "RIGHT"
                          ]
                        }
                      }
                    }
                  }
                }
              },
              "limits": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "maxComments",
                  "maxBodyBytes"
                ],
                "properties": {
                  "maxComments": {
                    "type": "integer",
                    "minimum": 0
                  },
                  "maxBodyBytes": {
                    "type": "integer",
                    "minimum": 1
                  }
                }
              },
              "dryRun": {
                "type": "boolean"
              },
              "idempotencyKey": {
                "type": "string",
                "minLength": 1
              },
              "preconditions": {
                "type": "array",
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "required": [
                    "field",
                    "operator"
                  ],
                  "properties": {
                    "field": {
                      "type": "string",
                      "enum": [
                        "state",
                        "head",
                        "reviews",
                        "reviewBodies"
                      ]
                    },
                    "operator": {
                      "type": "string",
                      "enum": [
                        "equals",
                        "no-newer-own-review",
                        "not-contains"
                      ]
                    },
                    "value": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          },
          "artifactIdentity": {
            "type": "object",
            "additionalProperties": true
          },
          "artifacts": {
            "type": "object",
            "additionalProperties": false,
            "required": [
              "result",
              "candidates",
              "judgments",
              "report",
              "cost",
              "health",
              "inputs",
              "diff"
            ],
            "properties": {
              "result": {
                "type": "object",
                "additionalProperties": true
              },
              "candidates": {
                "type": "object",
                "additionalProperties": true
              },
              "judgments": {
                "type": "object",
                "additionalProperties": true
              },
              "report": {
                "type": "string"
              },
              "cost": {
                "type": "string"
              },
              "health": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "schemaVersion",
                  "plannerMode",
                  "decisionStatus",
                  "discovery",
                  "findings",
                  "modelCalls"
                ],
                "properties": {
                  "schemaVersion": {
                    "type": "integer",
                    "enum": [
                      1
                    ]
                  },
                  "plannerMode": {
                    "type": "string",
                    "enum": [
                      "refuse",
                      "skipped",
                      "noop",
                      "advance",
                      "full",
                      "incremental"
                    ]
                  },
                  "decisionStatus": {
                    "type": "string",
                    "enum": [
                      "refuse",
                      "skipped",
                      "noop",
                      "advance",
                      "reviewed",
                      "failed"
                    ]
                  },
                  "discovery": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "attempts",
                      "selectedToolkitRoles",
                      "plannedAreaIds",
                      "retryAttempted",
                      "retryRecovered"
                    ],
                    "properties": {
                      "attempts": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "member",
                            "role",
                            "instance",
                            "attempt",
                            "outcome",
                            "failureMessage"
                          ],
                          "properties": {
                            "member": {
                              "type": "string",
                              "minLength": 1
                            },
                            "role": {
                              "type": "string",
                              "minLength": 1
                            },
                            "instance": {
                              "type": "string",
                              "minLength": 1
                            },
                            "attempt": {
                              "type": "integer",
                              "enum": [
                                0,
                                1
                              ]
                            },
                            "outcome": {
                              "type": "string",
                              "enum": [
                                "accepted",
                                "agent_call_failed",
                                "response_validation_failed"
                              ]
                            },
                            "failureMessage": {
                              "type": [
                                "string",
                                "null"
                              ],
                              "maxLength": 512
                            }
                          }
                        }
                      },
                      "selectedToolkitRoles": {
                        "type": "array",
                        "items": {
                          "type": "string",
                          "minLength": 1
                        }
                      },
                      "plannedAreaIds": {
                        "type": "array",
                        "items": {
                          "type": "string",
                          "minLength": 1
                        }
                      },
                      "retryAttempted": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 9007199254740991
                      },
                      "retryRecovered": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 9007199254740991
                      }
                    }
                  },
                  "findings": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "members",
                      "totalRawFindings",
                      "candidates",
                      "representedPoolIndexes",
                      "candidateCoverageComplete"
                    ],
                    "properties": {
                      "members": {
                        "type": "array",
                        "items": [
                          {
                            "type": "object",
                            "additionalProperties": false,
                            "required": [
                              "member",
                              "rawFindings"
                            ],
                            "properties": {
                              "member": {
                                "type": "string",
                                "enum": [
                                  "claude-code--pr-review-toolkit"
                                ]
                              },
                              "rawFindings": {
                                "type": "integer",
                                "minimum": 0,
                                "maximum": 9007199254740991
                              }
                            }
                          },
                          {
                            "type": "object",
                            "additionalProperties": false,
                            "required": [
                              "member",
                              "rawFindings"
                            ],
                            "properties": {
                              "member": {
                                "type": "string",
                                "enum": [
                                  "dynamic-review-areas"
                                ]
                              },
                              "rawFindings": {
                                "type": "integer",
                                "minimum": 0,
                                "maximum": 9007199254740991
                              }
                            }
                          }
                        ]
                      },
                      "totalRawFindings": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 9007199254740991
                      },
                      "candidates": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 9007199254740991
                      },
                      "representedPoolIndexes": {
                        "type": "integer",
                        "minimum": 0,
                        "maximum": 9007199254740991
                      },
                      "candidateCoverageComplete": {
                        "type": "boolean"
                      }
                    }
                  },
                  "modelCalls": {
                    "type": [
                      "integer",
                      "null"
                    ],
                    "minimum": 0,
                    "maximum": 9007199254740991
                  }
                }
              },
              "inputs": {
                "type": "object",
                "additionalProperties": true
              },
              "diff": {
                "type": "string"
              }
            }
          }
        }
      },
      "artifacts": {
        "schemaVersion": 1,
        "identityPointer": "/artifactIdentity",
        "maxMembers": 8,
        "maxTotalBytes": 134217728,
        "members": [
          {
            "name": "result",
            "path": "result.json",
            "pointer": "/artifacts/result",
            "encoding": "canonical-json",
            "required": true,
            "mediaType": "application/json",
            "maxBytes": 1048576
          },
          {
            "name": "candidates",
            "path": "candidates.json",
            "pointer": "/artifacts/candidates",
            "encoding": "canonical-json",
            "required": true,
            "mediaType": "application/json",
            "maxBytes": 8388608
          },
          {
            "name": "judgments",
            "path": "judgments.json",
            "pointer": "/artifacts/judgments",
            "encoding": "canonical-json",
            "required": true,
            "mediaType": "application/json",
            "maxBytes": 8388608
          },
          {
            "name": "report",
            "path": "REPORT.md",
            "pointer": "/artifacts/report",
            "encoding": "utf-8-text",
            "required": true,
            "mediaType": "text/markdown",
            "maxBytes": 8388608
          },
          {
            "name": "cost",
            "path": "COST.md",
            "pointer": "/artifacts/cost",
            "encoding": "utf-8-text",
            "required": true,
            "mediaType": "text/markdown",
            "maxBytes": 4194304
          },
          {
            "name": "health",
            "path": "HEALTH.json",
            "pointer": "/artifacts/health",
            "encoding": "canonical-json",
            "required": true,
            "mediaType": "application/json",
            "maxBytes": 1048576
          },
          {
            "name": "inputs",
            "path": "INPUTS.json",
            "pointer": "/artifacts/inputs",
            "encoding": "canonical-json",
            "required": true,
            "mediaType": "application/json",
            "maxBytes": 67108864
          },
          {
            "name": "diff",
            "path": "diff.patch",
            "pointer": "/artifacts/diff",
            "encoding": "utf-8-text",
            "required": true,
            "mediaType": "text/x-diff",
            "maxBytes": 33554432
          }
        ]
      }
    }
  },
  "deployment": {
    "schemaVersion": 1,
    "modes": [
      {
        "id": "local",
        "label": "Run locally",
        "target": {
          "kind": "repository"
        },
        "runtime": {
          "placement": "local",
          "provider": "gaw-local"
        },
        "trigger": {
          "kind": "manual"
        },
        "inputs": {
          "authority": "caller"
        }
      },
      {
        "id": "actions",
        "label": "Run from GitHub Actions",
        "target": {
          "kind": "repository"
        },
        "runtime": {
          "placement": "cloud",
          "provider": "github-actions"
        },
        "trigger": {
          "kind": "manual"
        },
        "inputs": {
          "authority": "caller"
        }
      }
    ]
  },
  "phases": [
    {
      "title": "Observe PR",
      "detail": "Receive the producer-observed pull-request facts and review target."
    },
    {
      "title": "Plan Review",
      "detail": "Validate the facts and choose the full, incremental, advance, skip, or refusal review window deterministically."
    },
    {
      "title": "Run Reviewers",
      "detail": "Plan and run the toolkit-specialist and semantic-area reviewer groups in parallel."
    },
    {
      "title": "Merge Findings",
      "detail": "Normalize and deduplicate raw findings into the candidate ledger."
    },
    {
      "title": "Judge Findings",
      "detail": "Have true-positive and false-positive advocates debate each verification unit, then judge it against the candidate evidence."
    },
    {
      "title": "Prepare Results",
      "detail": "Render the judged report, post descriptor, health data, and governed artifacts."
    }
  ]
};

const Planner = (() => {
/**
 * Deterministic, side-effect-free review-window planner.
 *
 * This is workload code, not a GAW engine capability.  Producers supply only
 * observed git/GitHub facts; this module owns marker selection and all mode
 * decisions.
 */

const SHA_RE = /^[0-9a-f]{40}$/;
const DIGEST_RE = /^sha256:[0-9a-f]{64}$/;
const HEX_256_RE = /^[0-9a-f]{64}$/;
const GITHUB_TIMESTAMP_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;
const MARKER_RE = /<!--[ \t\r\n\f\v]*deep-code-review:v1[ \t\r\n\f\v]+(\{.*?\})[ \t\r\n\f\v]*-->/gs;
const GITHUB_ACTIONS_POSTING_LOGIN = "github-actions[bot]";
const STRATEGIES = new Set(["once", "automatic", "full"]);
const MODES = new Set(["refuse", "skipped", "noop", "advance", "full", "incremental"]);
const UTF8_ENCODER = new TextEncoder();
const SHA256_K = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

class PlannerError extends Error {
  constructor(message, code = "PLANNER_FACTS_INVALID") {
    super(message);
    this.name = "PlannerError";
    this.code = code;
  }
}

function fail(message, code) {
  throw new PlannerError(message, code);
}

function assertValidUnicode(value) {
  for (let index = 0; index < value.length; index += 1) {
    const code = value.charCodeAt(index);
    if (code >= 0xd800 && code <= 0xdbff) {
      const next = value.charCodeAt(index + 1);
      if (!(next >= 0xdc00 && next <= 0xdfff)) {
        fail("facts contain an unpaired UTF-16 surrogate");
      }
      index += 1;
    } else if (code >= 0xdc00 && code <= 0xdfff) {
      fail("facts contain an unpaired UTF-16 surrogate");
    }
  }
}

function assertValidUnicodeTree(value, seen = new Set()) {
  if (typeof value === "string") {
    assertValidUnicode(value);
    return;
  }
  if (!value || typeof value !== "object") return;
  if (seen.has(value)) fail("facts must not contain cyclic objects");
  seen.add(value);
  if (Array.isArray(value)) {
    for (const item of value) assertValidUnicodeTree(item, seen);
  } else {
    for (const [key, item] of Object.entries(value)) {
      assertValidUnicode(key);
      assertValidUnicodeTree(item, seen);
    }
  }
  seen.delete(value);
}

function jsonString(value, asciiOnly) {
  assertValidUnicode(value);
  const encoded = JSON.stringify(value);
  return asciiOnly
    ? encoded.replace(/[\u007f-\uffff]/g, (character) => `\\u${character.charCodeAt(0).toString(16).padStart(4, "0")}`)
    : encoded;
}

function canonicalJson(value, asciiOnly = false) {
  if (value === null || typeof value === "boolean") {
    return JSON.stringify(value);
  }
  if (typeof value === "string") {
    return jsonString(value, asciiOnly);
  }
  if (typeof value === "number" && Number.isSafeInteger(value)) {
    return String(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map((item) => canonicalJson(item, asciiOnly)).join(",")}]`;
  }
  if (value && typeof value === "object") {
    return `{${Object.keys(value).sort().map((key) => `${jsonString(key, asciiOnly)}:${canonicalJson(value[key], asciiOnly)}`).join(",")}}`;
  }
  fail("facts contain a value that cannot be canonicalized");
}

function rotateRight(value, count) {
  return (value >>> count) | (value << (32 - count));
}

function sha256Hex(text) {
  const input = UTF8_ENCODER.encode(text);
  const bitLength = input.length * 8;
  const paddedLength = Math.ceil((input.length + 9) / 64) * 64;
  const bytes = new Uint8Array(paddedLength);
  bytes.set(input);
  bytes[input.length] = 0x80;
  const view = new DataView(bytes.buffer);
  view.setUint32(paddedLength - 8, Math.floor(bitLength / 0x100000000), false);
  view.setUint32(paddedLength - 4, bitLength >>> 0, false);

  const state = new Uint32Array([
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ]);
  const words = new Uint32Array(64);
  for (let offset = 0; offset < bytes.length; offset += 64) {
    for (let index = 0; index < 16; index += 1) {
      words[index] = view.getUint32(offset + index * 4, false);
    }
    for (let index = 16; index < 64; index += 1) {
      const s0 = rotateRight(words[index - 15], 7) ^ rotateRight(words[index - 15], 18) ^ (words[index - 15] >>> 3);
      const s1 = rotateRight(words[index - 2], 17) ^ rotateRight(words[index - 2], 19) ^ (words[index - 2] >>> 10);
      words[index] = (words[index - 16] + s0 + words[index - 7] + s1) >>> 0;
    }
    let [a, b, c, d, e, f, g, h] = state;
    for (let index = 0; index < 64; index += 1) {
      const sigma1 = rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25);
      const choice = (e & f) ^ (~e & g);
      const temp1 = (h + sigma1 + choice + SHA256_K[index] + words[index]) >>> 0;
      const sigma0 = rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22);
      const majority = (a & b) ^ (a & c) ^ (b & c);
      const temp2 = (sigma0 + majority) >>> 0;
      h = g;
      g = f;
      f = e;
      e = (d + temp1) >>> 0;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) >>> 0;
    }
    state[0] = (state[0] + a) >>> 0;
    state[1] = (state[1] + b) >>> 0;
    state[2] = (state[2] + c) >>> 0;
    state[3] = (state[3] + d) >>> 0;
    state[4] = (state[4] + e) >>> 0;
    state[5] = (state[5] + f) >>> 0;
    state[6] = (state[6] + g) >>> 0;
    state[7] = (state[7] + h) >>> 0;
  }
  return [...state].map((word) => word.toString(16).padStart(8, "0")).join("");
}

function digestValue(value) {
  return `sha256:${sha256Hex(canonicalJson(value))}`;
}

function leaseIdentityDigest(value) {
  return `sha256:${sha256Hex(canonicalJson(value, true))}`;
}

function object(value, path, keys) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    fail(`${path} must be an object`);
  }
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  if (actual.length !== expected.length || actual.some((key, i) => key !== expected[i])) {
    fail(`${path} must have exactly these keys: ${expected.join(", ")}`);
  }
  return value;
}

function optionalObject(value, path, required, optional) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    fail(`${path} must be an object`);
  }
  const allowed = new Set([...required, ...optional]);
  const actual = Object.keys(value);
  for (const key of required) {
    if (!(key in value)) fail(`${path}.${key} is required`);
  }
  for (const key of actual) {
    if (!allowed.has(key)) fail(`${path}.${key} is not allowed`);
  }
  return value;
}

function dictionary(value, path) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    fail(`${path} must be an object`);
  }
  return value;
}

function string(value, path, { nonempty = true } = {}) {
  if (typeof value !== "string" || (nonempty && value.length === 0)) {
    fail(`${path} must be ${nonempty ? "a non-empty " : ""}string`);
  }
  return value;
}

function sha(value, path) {
  string(value, path);
  if (!SHA_RE.test(value)) fail(`${path} must be a lowercase 40-hex commit SHA`);
  return value;
}

function canonicalUtcSecond(value, path) {
  string(value, path);
  if (!GITHUB_TIMESTAMP_RE.test(value)) fail(`${path} must be a canonical UTC second timestamp`);
  const milliseconds = Date.parse(value);
  if (
    !Number.isFinite(milliseconds)
    || new Date(milliseconds).toISOString() !== value.replace("Z", ".000Z")
  ) {
    fail(`${path} must be a real canonical UTC second timestamp`);
  }
}

function digest(value, path) {
  string(value, path);
  if (!DIGEST_RE.test(value)) fail(`${path} must be a lowercase sha256 digest`);
  return value;
}

function hex256(value, path) {
  string(value, path);
  if (!HEX_256_RE.test(value)) fail(`${path} must be 64 lowercase hexadecimal characters`);
  return value;
}

function integer(value, path, { positive = false } = {}) {
  if (!Number.isSafeInteger(value) || (positive ? value <= 0 : value < 0)) {
    fail(`${path} must be a ${positive ? "positive" : "non-negative"} safe integer`);
  }
  return value;
}

function bool(value, path) {
  if (typeof value !== "boolean") fail(`${path} must be boolean`);
  return value;
}

function textArray(value, path, { nullable = false } = {}) {
  if (nullable && value === null) return value;
  if (!Array.isArray(value) || value.some((entry) => typeof entry !== "string")) {
    fail(`${path} must be ${nullable ? "null or " : ""}an array of strings`);
  }
  return value;
}

function parsePrUrl(serverUrl, prUrl) {
  let server;
  let pr;
  try {
    server = new URL(serverUrl);
    pr = new URL(prUrl);
  } catch {
    fail("request.serverUrl and request.prUrl must be absolute URLs", "PLANNER_URL_INVALID");
  }
  if (!["http:", "https:"].includes(server.protocol) || !["http:", "https:"].includes(pr.protocol)) {
    fail("request URLs must use http or https", "PLANNER_URL_INVALID");
  }
  if (server.origin !== pr.origin) {
    fail(`refusing PR origin ${pr.origin}; expected configured origin ${server.origin}`, "PLANNER_URL_INVALID");
  }
  const match = /^\/([^/]+)\/([^/]+)\/pull\/([1-9][0-9]*)\/?$/.exec(pr.pathname);
  if (!match) fail(`could not parse canonical PR URL: ${prUrl}`, "PLANNER_URL_INVALID");
  return { owner: match[1], repo: match[2], number: Number(match[3]) };
}

function markerTuples(review) {
  const tuples = [];
  let firstLexicalMarker = true;
  for (const match of review.body.matchAll(MARKER_RE)) {
    const firstInReview = firstLexicalMarker;
    firstLexicalMarker = false;
    let payload;
    try {
      payload = JSON.parse(match[1]);
    } catch {
      continue;
    }
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) continue;
    if (typeof payload.reviewed_head !== "string" || !SHA_RE.test(payload.reviewed_head)) continue;
    const reviewedMergeBase = typeof payload.reviewed_merge_base === "string" && SHA_RE.test(payload.reviewed_merge_base)
      ? payload.reviewed_merge_base
      : undefined;
    tuples.push({
      reviewId: review.id,
      bodyByteOffset: UTF8_ENCODER.encode(review.body.slice(0, match.index)).length,
      reviewedHead: payload.reviewed_head,
      ...(reviewedMergeBase === undefined ? {} : { reviewedMergeBase }),
      payload,
      firstInReview,
    });
  }
  return tuples;
}

function tupleKey(tuple) {
  return `${tuple.reviewId}:${tuple.bodyByteOffset}:${tuple.reviewedHead}:${tuple.reviewedMergeBase ?? ""}`;
}

function reprojectionKey(prevHead, priorMergeBase) {
  return `${prevHead}:${priorMergeBase ?? ""}`;
}

/**
 * Validate the concrete ReviewFactsV2 subset used by this implementation.
 * It returns parsed marker material for planReview; callers may use it to
 * reject a producer bundle before any model work begins.
 */
function validateReviewFactsV2(facts) {
  assertValidUnicodeTree(facts);
  object(facts, "facts", [
    "actor",
    "execution",
    "git",
    "markerIndex",
    "ownedResources",
    "pr",
    "promptBundle",
    "request",
    "reviews",
    "schemaVersion",
  ]);
  if (facts.schemaVersion !== 2) fail("facts.schemaVersion must be 2");

  object(facts.execution, "facts.execution", ["generatedAt", "postingLogin", "workspace"]);
  canonicalUtcSecond(
    facts.execution.generatedAt,
    "facts.execution.generatedAt",
  );
  string(facts.execution.postingLogin, "facts.execution.postingLogin");
  object(
    facts.execution.workspace,
    "facts.execution.workspace",
    ["head", "relativePath", "resourceRole", "tree"],
  );
  if (facts.execution.workspace.resourceRole !== "container") {
    fail("facts.execution.workspace.resourceRole must be container");
  }
  string(
    facts.execution.workspace.relativePath,
    "facts.execution.workspace.relativePath",
  );
  if (
    facts.execution.workspace.relativePath.startsWith("/")
    || facts.execution.workspace.relativePath.includes("\\")
    || facts.execution.workspace.relativePath
      .split("/")
      .some((part) => part === "" || part === "." || part === "..")
  ) {
    fail("facts.execution.workspace.relativePath must be a safe POSIX relative path");
  }
  sha(facts.execution.workspace.head, "facts.execution.workspace.head");
  sha(facts.execution.workspace.tree, "facts.execution.workspace.tree");

  const request = optionalObject(
    facts.request,
    "facts.request",
    ["dryRun", "serverUrl", "prUrl", "strategy"],
    ["expectedHead"],
  );
  string(request.serverUrl, "facts.request.serverUrl");
  string(request.prUrl, "facts.request.prUrl");
  bool(request.dryRun, "facts.request.dryRun");
  if (!STRATEGIES.has(request.strategy)) fail("facts.request.strategy must be once, automatic, or full");
  if ("expectedHead" in request) sha(request.expectedHead, "facts.request.expectedHead");
  const requestedPr = parsePrUrl(request.serverUrl, request.prUrl);

  object(facts.actor, "facts.actor", ["login"]);
  string(facts.actor.login, "facts.actor.login");

  object(facts.pr, "facts.pr", ["base", "body", "head", "merged", "number", "owner", "ref", "repo", "state", "title"]);
  string(facts.pr.owner, "facts.pr.owner");
  string(facts.pr.repo, "facts.pr.repo");
  integer(facts.pr.number, "facts.pr.number", { positive: true });
  string(facts.pr.state, "facts.pr.state");
  bool(facts.pr.merged, "facts.pr.merged");
  sha(facts.pr.head, "facts.pr.head");
  sha(facts.pr.base, "facts.pr.base");
  string(facts.pr.ref, "facts.pr.ref");
  string(facts.pr.title, "facts.pr.title", { nonempty: false });
  string(facts.pr.body, "facts.pr.body", { nonempty: false });
  if (facts.execution.workspace.head !== facts.pr.head) {
    fail("facts.execution.workspace.head must equal facts.pr.head");
  }
  if (
    requestedPr.owner !== facts.pr.owner ||
    requestedPr.repo !== facts.pr.repo ||
    requestedPr.number !== facts.pr.number
  ) {
    fail("request.prUrl does not match facts.pr", "PLANNER_URL_INVALID");
  }

  object(facts.promptBundle, "facts.promptBundle", [
    "bundleDigest",
    "members",
    "schemaVersion",
    "workflowDigest",
  ]);
  if (facts.promptBundle.schemaVersion !== 1) fail("facts.promptBundle.schemaVersion must be 1");
  digest(facts.promptBundle.workflowDigest, "facts.promptBundle.workflowDigest");
  digest(facts.promptBundle.bundleDigest, "facts.promptBundle.bundleDigest");
  if (!Array.isArray(facts.promptBundle.members)) fail("facts.promptBundle.members must be an array");
  const promptPaths = new Set();
  for (const [index, member] of facts.promptBundle.members.entries()) {
    object(member, `facts.promptBundle.members[${index}]`, ["bytes", "path", "sha256"]);
    string(member.path, `facts.promptBundle.members[${index}].path`);
    if (member.path.startsWith("/") || member.path.split("/").some((part) => part === "." || part === ".." || part === "")) {
      fail(`facts.promptBundle.members[${index}].path must be a safe relative path`);
    }
    if (promptPaths.has(member.path)) fail(`facts.promptBundle.members contains duplicate path ${member.path}`);
    promptPaths.add(member.path);
    digest(member.sha256, `facts.promptBundle.members[${index}].sha256`);
    integer(member.bytes, `facts.promptBundle.members[${index}].bytes`);
  }
  const promptPreimage = {
    schemaVersion: facts.promptBundle.schemaVersion,
    workflowDigest: facts.promptBundle.workflowDigest,
    members: facts.promptBundle.members,
  };
  if (digestValue(promptPreimage) !== facts.promptBundle.bundleDigest) {
    fail("facts.promptBundle.bundleDigest does not match its canonical manifest");
  }

  object(facts.ownedResources, "facts.ownedResources", ["identity", "identityDigest", "schemaVersion"]);
  if (facts.ownedResources.schemaVersion !== 1) fail("facts.ownedResources.schemaVersion must be 1");
  digest(facts.ownedResources.identityDigest, "facts.ownedResources.identityDigest");
  const lease = facts.ownedResources.identity;
  object(lease, "facts.ownedResources.identity", [
    "backend",
    "leaseId",
    "nonce",
    "resources",
    "runIdentity",
    "schemaVersion",
    "scratchRoot",
    "workflowDigest",
  ]);
  if (lease.schemaVersion !== 1) fail("facts.ownedResources.identity.schemaVersion must be 1");
  hex256(lease.leaseId, "facts.ownedResources.identity.leaseId");
  hex256(lease.nonce, "facts.ownedResources.identity.nonce");
  if (lease.leaseId !== lease.nonce) fail("facts.ownedResources.identity.leaseId must equal nonce");
  string(lease.backend, "facts.ownedResources.identity.backend");
  string(lease.runIdentity, "facts.ownedResources.identity.runIdentity");
  digest(lease.workflowDigest, "facts.ownedResources.identity.workflowDigest");
  if (lease.workflowDigest !== facts.promptBundle.workflowDigest) {
    fail("facts.ownedResources.identity.workflowDigest must equal facts.promptBundle.workflowDigest");
  }
  string(lease.scratchRoot, "facts.ownedResources.identity.scratchRoot");
  if (!lease.scratchRoot.startsWith("/") || lease.scratchRoot === "/") {
    fail("facts.ownedResources.identity.scratchRoot must be an absolute non-root path");
  }
  if (lease.scratchRoot.slice(1).split("/").some((part) => part === "." || part === ".." || part === "")) {
    fail("facts.ownedResources.identity.scratchRoot must be canonical");
  }
  if (!Array.isArray(lease.resources) || lease.resources.length !== 2) {
    fail("facts.ownedResources.identity.resources must contain the container and allocation-staging paths");
  }
  const resourceRoles = new Set();
  const resourcePaths = new Set();
  for (const [index, resource] of lease.resources.entries()) {
    object(resource, `facts.ownedResources.identity.resources[${index}]`, ["path", "role"]);
    string(resource.path, `facts.ownedResources.identity.resources[${index}].path`);
    string(resource.role, `facts.ownedResources.identity.resources[${index}].role`);
    if (!["container", "allocation-staging"].includes(resource.role)) {
      fail(`facts.ownedResources.identity.resources[${index}].role is unsupported`);
    }
    if (resourceRoles.has(resource.role)) fail(`facts.ownedResources.identity.resources duplicates role ${resource.role}`);
    if (resourcePaths.has(resource.path)) fail(`facts.ownedResources.identity.resources duplicates path ${resource.path}`);
    resourceRoles.add(resource.role);
    resourcePaths.add(resource.path);
    if (!resource.path.startsWith(`${lease.scratchRoot}/`)) {
      fail(`facts.ownedResources.identity.resources[${index}].path must be beneath scratchRoot`);
    }
    const relativePath = resource.path.slice(lease.scratchRoot.length + 1);
    if (relativePath.includes("/") || [".", "..", ""].includes(relativePath)) {
      fail(`facts.ownedResources.identity.resources[${index}].path must be a canonical direct child`);
    }
  }
  if (leaseIdentityDigest(lease) !== facts.ownedResources.identityDigest) {
    fail("facts.ownedResources.identityDigest does not match its canonical identity");
  }

  if (!Array.isArray(facts.reviews)) fail("facts.reviews must be an array");
  const trustedReviewLogins = new Set([
    facts.actor.login,
    facts.execution.postingLogin,
    GITHUB_ACTIONS_POSTING_LOGIN,
  ]);
  const reviews = new Map();
  for (const [index, review] of facts.reviews.entries()) {
    object(review, `facts.reviews[${index}]`, ["authorLogin", "body", "id", "submittedAt"]);
    integer(review.id, `facts.reviews[${index}].id`, { positive: true });
    string(review.authorLogin, `facts.reviews[${index}].authorLogin`);
    if (!trustedReviewLogins.has(review.authorLogin)) {
      fail(`facts.reviews[${index}].authorLogin is not a trusted review identity`);
    }
    if (review.submittedAt !== null) {
      string(review.submittedAt, `facts.reviews[${index}].submittedAt`);
    }
    if (
      review.submittedAt !== null
      && (
        !GITHUB_TIMESTAMP_RE.test(review.submittedAt)
        || review.submittedAt.startsWith("0000-")
        || Number.isNaN(Date.parse(review.submittedAt))
        || new Date(Date.parse(review.submittedAt))
          .toISOString()
          .replace(".000Z", "Z") !== review.submittedAt
      )
    ) {
      fail(`facts.reviews[${index}].submittedAt must be a canonical GitHub UTC timestamp`);
    }
    string(review.body, `facts.reviews[${index}].body`, { nonempty: false });
    if (reviews.has(review.id)) fail(`facts.reviews contains duplicate id ${review.id}`);
    reviews.set(review.id, review);
  }

  if (!Array.isArray(facts.markerIndex)) fail("facts.markerIndex must be an array");
  const indexByTuple = new Map();
  for (const [index, marker] of facts.markerIndex.entries()) {
    optionalObject(
      marker,
      `facts.markerIndex[${index}]`,
      ["bodyByteOffset", "reviewId", "reviewedHead"],
      ["reviewedMergeBase"],
    );
    integer(marker.reviewId, `facts.markerIndex[${index}].reviewId`, { positive: true });
    integer(marker.bodyByteOffset, `facts.markerIndex[${index}].bodyByteOffset`);
    sha(marker.reviewedHead, `facts.markerIndex[${index}].reviewedHead`);
    if ("reviewedMergeBase" in marker) sha(marker.reviewedMergeBase, `facts.markerIndex[${index}].reviewedMergeBase`);
    const key = tupleKey(marker);
    if (indexByTuple.has(key)) fail(`facts.markerIndex contains duplicate tuple ${key}`);
    indexByTuple.set(key, marker);
  }

  const parsedTuples = [];
  for (const review of reviews.values()) parsedTuples.push(...markerTuples(review));
  for (const tuple of parsedTuples) {
    if (!indexByTuple.has(tupleKey(tuple))) {
      fail(`facts.markerIndex omits lexical marker tuple ${tupleKey(tuple)}`);
    }
  }
  // The index may be a superset, but every asserted tuple must still be
  // grounded in the immutable raw body. It cannot inject a decision candidate.
  for (const marker of indexByTuple.values()) {
    if (!parsedTuples.some((tuple) => tupleKey(tuple) === tupleKey(marker))) {
      fail(`facts.markerIndex tuple ${tupleKey(marker)} is not present in a raw review body`);
    }
  }

  object(facts.git, "facts.git", [
    "anchorBase",
    "anchorDiff",
    "anchorHead",
    "currentChangedFiles",
    "currentMergeBase",
    "currentMergeBaseIsAncestorOfBase",
    "currentMergeBaseIsAncestorOfHead",
    "objectRetrievability",
    "reprojections",
  ]);
  sha(facts.git.currentMergeBase, "facts.git.currentMergeBase");
  sha(facts.git.anchorBase, "facts.git.anchorBase");
  sha(facts.git.anchorHead, "facts.git.anchorHead");
  bool(facts.git.currentMergeBaseIsAncestorOfBase, "facts.git.currentMergeBaseIsAncestorOfBase");
  bool(facts.git.currentMergeBaseIsAncestorOfHead, "facts.git.currentMergeBaseIsAncestorOfHead");
  if (facts.git.anchorBase !== facts.git.currentMergeBase) {
    fail("facts.git.anchorBase must equal facts.git.currentMergeBase");
  }
  if (facts.git.anchorHead !== facts.pr.head) {
    fail("facts.git.anchorHead must equal facts.pr.head");
  }
  if (!facts.git.currentMergeBaseIsAncestorOfBase) {
    fail("facts.git.currentMergeBaseIsAncestorOfBase must be true");
  }
  if (!facts.git.currentMergeBaseIsAncestorOfHead) {
    fail("facts.git.currentMergeBaseIsAncestorOfHead must be true");
  }
  string(facts.git.anchorDiff, "facts.git.anchorDiff", { nonempty: false });
  textArray(facts.git.currentChangedFiles, "facts.git.currentChangedFiles");
  dictionary(facts.git.objectRetrievability, "facts.git.objectRetrievability");
  for (const [objectId, retrievable] of Object.entries(facts.git.objectRetrievability)) {
    sha(objectId, `facts.git.objectRetrievability key ${JSON.stringify(objectId)}`);
    bool(retrievable, `facts.git.objectRetrievability[${JSON.stringify(objectId)}]`);
  }
  for (const required of [facts.pr.head, facts.pr.base, facts.git.currentMergeBase]) {
    if (facts.git.objectRetrievability[required] !== true) {
      fail(`facts.git.objectRetrievability must prove current object ${required} is retrievable`);
    }
    if ((facts.git.anchorDiff.length === 0) !== (facts.git.currentChangedFiles.length === 0)) {
      fail("facts.git.anchorDiff and facts.git.currentChangedFiles disagree about whether the current diff is empty");
    }
  }

  if (!Array.isArray(facts.git.reprojections)) fail("facts.git.reprojections must be an array");
  const reprojectByKey = new Map();
  for (const [index, record] of facts.git.reprojections.entries()) {
    object(record, `facts.git.reprojections[${index}]`, [
      "conflicted",
      "currentHead",
      "currentMergeBase",
      "prevHead",
      "priorMergeBase",
      "structuralError",
      "syntheticBase",
      "windowDiff",
      "windowFiles",
    ]);
    sha(record.currentMergeBase, `facts.git.reprojections[${index}].currentMergeBase`);
    sha(record.currentHead, `facts.git.reprojections[${index}].currentHead`);
    if (record.currentMergeBase !== facts.git.currentMergeBase) {
      fail(`facts.git.reprojections[${index}].currentMergeBase must equal facts.git.currentMergeBase`);
    }
    if (record.currentHead !== facts.pr.head) {
      fail(`facts.git.reprojections[${index}].currentHead must equal facts.pr.head`);
    }
    sha(record.prevHead, `facts.git.reprojections[${index}].prevHead`);
    if (record.priorMergeBase !== null) sha(record.priorMergeBase, `facts.git.reprojections[${index}].priorMergeBase`);
    bool(record.structuralError, `facts.git.reprojections[${index}].structuralError`);
    bool(record.conflicted, `facts.git.reprojections[${index}].conflicted`);
    if (record.structuralError) {
      if (record.conflicted || record.syntheticBase !== null || record.windowDiff !== null || record.windowFiles !== null) {
        fail(`facts.git.reprojections[${index}] structural errors must have null merge outputs`);
      }
    } else {
      sha(record.syntheticBase, `facts.git.reprojections[${index}].syntheticBase`);
      string(record.windowDiff, `facts.git.reprojections[${index}].windowDiff`, { nonempty: false });
      textArray(record.windowFiles, `facts.git.reprojections[${index}].windowFiles`);
      if ((record.windowDiff.length === 0) !== (record.windowFiles.length === 0)) {
        fail(`facts.git.reprojections[${index}].windowDiff and windowFiles disagree about emptiness`);
      }
    }
    const key = reprojectionKey(record.prevHead, record.priorMergeBase);
    if (reprojectByKey.has(key)) fail(`facts.git.reprojections has contradictory duplicate record ${key}`);
    reprojectByKey.set(key, record);
  }

  const requiredReprojections = new Set();
  for (const marker of indexByTuple.values()) {
    requiredReprojections.add(reprojectionKey(marker.reviewedHead, null));
    if (marker.reviewedMergeBase !== undefined) {
      requiredReprojections.add(reprojectionKey(marker.reviewedHead, marker.reviewedMergeBase));
    }
    for (const objectId of [marker.reviewedHead, marker.reviewedMergeBase].filter(Boolean)) {
      if (!(objectId in facts.git.objectRetrievability)) {
        fail(`facts.git.objectRetrievability omits marker-referenced object ${objectId}`);
      }
    }
  }
  for (const key of reprojectByKey.keys()) {
    if (!requiredReprojections.has(key)) fail(`facts.git.reprojections contains unenumerated record ${key}`);
  }
  for (const key of requiredReprojections) {
    if (!reprojectByKey.has(key)) fail(`facts.git.reprojections omits required record ${key}`);
  }

  return { request, reviews, parsedTuples, reprojectByKey };
}

function emptyPlan(facts) {
  return {
    owner: facts.pr.owner,
    repo: facts.pr.repo,
    repoSlug: `${facts.pr.owner}/${facts.pr.repo}`,
    pr: facts.pr.number,
    prUrl: facts.request.prUrl,
    title: facts.pr.title,
    baseRef: facts.pr.ref,
    actor: facts.actor.login,
    state: facts.pr.state,
    curHead: facts.pr.head,
    newMergeBase: null,
    baseT: null,
    prevHead: null,
    prevMergeBase: null,
    prevHeadRetrievable: null,
    anchorDiff: facts.git.anchorDiff,
    windowDiff: null,
    windowFiles: null,
    conflicted: false,
    legacyPrevMarker: false,
    mode: null,
    reason: null,
  };
}

function ownValidMarkers(facts, parsedTuples, reviews) {
  const slug = `${facts.pr.owner}/${facts.pr.repo}`;
  const trustedPostingLogins = new Set([
    facts.execution.postingLogin,
    "github-actions[bot]",
  ]);
  const markers = [];
  for (const tuple of parsedTuples) {
    // The oracle uses re.search, so only a review body's first marker can be
    // its review anchor. All lexical tuples remain enumerated for fact checks.
    if (!tuple.firstInReview) continue;
    const review = reviews.get(tuple.reviewId);
    if (!trustedPostingLogins.has(review.authorLogin)) continue;
    if (tuple.payload.repo !== slug || tuple.payload.pr !== facts.pr.number) continue;
    markers.push({
      submittedAt: review.submittedAt,
      id: review.id,
      reviewedHead: tuple.reviewedHead,
      reviewedMergeBase: tuple.reviewedMergeBase ?? null,
    });
  }
  return markers.sort((a, b) => (
    a.submittedAt === null && b.submittedAt !== null ? -1
      : a.submittedAt !== null && b.submittedAt === null ? 1
        : a.submittedAt < b.submittedAt ? -1
          : a.submittedAt > b.submittedAt ? 1
        : a.id - b.id
  ));
}

function setMode(plan, mode, reason, fields = {}) {
  if (!MODES.has(mode)) fail(`unsupported planner mode ${mode}`);
  return { ...plan, ...fields, mode, reason };
}

function planReview(facts) {
  const validated = validateReviewFactsV2(facts);
  let plan = emptyPlan(facts);

  if (facts.pr.merged || facts.pr.state !== "open") {
    return setMode(plan, "refuse", `PR is ${facts.pr.merged ? "merged" : facts.pr.state}; nothing to review`);
  }
  if ("expectedHead" in facts.request && facts.pr.head !== facts.request.expectedHead) {
    return setMode(
      plan,
      "refuse",
      `head moved ${facts.request.expectedHead.slice(0, 10)} -> ${facts.pr.head.slice(0, 10)} since this run was admitted; not reviewing a commit the caller did not approve`,
    );
  }

  const markers = ownValidMarkers(facts, validated.parsedTuples, validated.reviews);
  const previous = facts.request.strategy === "full" ? null : markers.at(-1) ?? null;
  if (facts.request.strategy === "once" && previous) {
    return setMode(
      plan,
      "skipped",
      `strategy=once: a prior deep-code-review:v1 review exists (reviewed_head ${previous.reviewedHead.slice(0, 10)}); not posting a follow-up`,
      { prevHead: previous.reviewedHead, prevMergeBase: previous.reviewedMergeBase },
    );
  }

  plan = { ...plan, newMergeBase: facts.git.currentMergeBase };
  const exact = facts.request.strategy === "full"
    ? null
    : markers.find((marker) => (
      marker.reviewedHead === facts.pr.head
      && marker.reviewedMergeBase === facts.git.currentMergeBase
    )) ?? null;
  if (exact !== null) {
    return setMode(
      {
        ...plan,
        prevHead: exact.reviewedHead,
        prevMergeBase: exact.reviewedMergeBase,
        prevHeadRetrievable: facts.git.objectRetrievability[exact.reviewedHead],
        legacyPrevMarker: false,
      },
      "noop",
      `already reviewed at ${facts.pr.head.slice(0, 10)} (head and merge base unchanged)`,
    );
  }
  if (!previous) {
    return setMode(
      plan,
      "full",
      facts.request.strategy === "full"
        ? "full review (strategy=full)"
        : "first review (no prior deep-code-review:v1 marker)",
      { baseT: facts.git.currentMergeBase },
    );
  }

  const prevHeadRetrievable = facts.git.objectRetrievability[previous.reviewedHead];
  plan = {
    ...plan,
    prevHead: previous.reviewedHead,
    prevMergeBase: previous.reviewedMergeBase,
    prevHeadRetrievable,
    legacyPrevMarker: previous.reviewedMergeBase === null,
  };
  if (!prevHeadRetrievable) {
    return setMode(
      plan,
      "full",
      `full review — last-reviewed commit ${previous.reviewedHead.slice(0, 10)} is unretrievable (force-pushed and gc'd); cannot reproject`,
      { baseT: facts.git.currentMergeBase },
    );
  }
  let selectedMergeBase = previous.reviewedMergeBase;
  if (selectedMergeBase !== null && !facts.git.objectRetrievability[selectedMergeBase]) {
    selectedMergeBase = null;
    plan = { ...plan, prevMergeBase: null, legacyPrevMarker: true };
  }
  const record = validated.reprojectByKey.get(reprojectionKey(previous.reviewedHead, selectedMergeBase));
  if (!record) fail("selected reprojection record is missing despite complete enumeration");
  if (record.structuralError) {
    return setMode(
      plan,
      "full",
      `full review — could not reproject the last-reviewed state (${previous.reviewedHead.slice(0, 10)}) onto today's base (merge-tree structural error)`,
      { baseT: facts.git.currentMergeBase },
    );
  }

  const legacyNote = selectedMergeBase === null
    ? " (legacy marker had no reviewed_merge_base; used auto merge-base — reduced retarget robustness)"
    : "";
  if (record.windowFiles.length === 0) {
    return setMode(
      plan,
      "advance",
      `no new author content since ${previous.reviewedHead.slice(0, 10)} (content-equivalent rewrite / clean upstream merge); advancing the anchor to ${facts.pr.head.slice(0, 10)}${legacyNote}`,
      {
        baseT: record.syntheticBase,
        windowDiff: record.windowDiff,
        windowFiles: record.windowFiles,
        conflicted: record.conflicted,
      },
    );
  }
  const conflictNote = record.conflicted ? " [includes conflicted file(s) shown with merge context]" : "";
  return setMode(
    plan,
    "incremental",
    `incremental (diff-of-diffs) — ${record.windowFiles.length} file(s) of new author content since ${previous.reviewedHead.slice(0, 10)}${conflictNote}${legacyNote}`,
    {
      baseT: record.syntheticBase,
      windowDiff: record.windowDiff,
      windowFiles: record.windowFiles,
      conflicted: record.conflicted,
    },
  );
}
return Object.freeze({ PlannerError, validateReviewFactsV2, planReview });
})();

const Normalize = (() => {
/**
 * Finding-pool normalization for the native Deep review workflow.
 *
 * The installed Python routine remains a migration oracle only.
 */

const SEVERITY = Object.freeze({
  critical: "critical",
  crit: "critical",
  blocker: "critical",
  high: "critical",
  p0: "critical",
  p1: "critical",
  moderate: "moderate",
  medium: "moderate",
  med: "moderate",
  major: "moderate",
  p2: "moderate",
  warning: "moderate",
  warn: "moderate",
  nit: "nit",
  low: "nit",
  minor: "nit",
  info: "nit",
  p3: "nit",
});
const CODEX_PRIORITY = Object.freeze({
  0: "critical",
  1: "critical",
  2: "moderate",
  3: "nit",
});
const JSON_FENCE_RE = /```json\s*([\s\S]*?)```/g;
const HEADING_RE = /^\s{0,3}#{1,6}\s+(.*)$/;
const FIELD_RE = /^\s*[*-]?\s*\*{0,2}(File|Lines?|Severity|Category|Problem|Claim|Description|Failure|Exploit Scenario|Evidence|Confidence|Recommendation|Suggested fix)\*{0,2}\s*:\s*(.*)$/i;
const FIELD_ANCHOR_RE = /^(.+?):(\d+)(?:\s*[-–]\s*(\d+))?\s*$/;
const LINE_FIELD_RE = /^L?(\d{1,7})(?:\s*[-–]\s*L?(\d{1,7}))?$/;
const INLINE_ANCHOR_RE = /([\w./@-]+):(\d+)(?:\s*[-–]\s*(\d+))?/;
const FENCE_DELIMITER_RE = /^(`{3,}|~{3,})(.*)$/;
const SEVERITY_CONFIDENCE_RE = /Severity:\s*([A-Za-z]+)\s*\|\s*Confidence:\s*(\d+)\s*\/\s*10/i;
const NOISE_RE = /no (significant )?issues found|no security vulnerabilities found|no issues found\./i;

function normalizeSeverity(value) {
  if (!value) return "moderate";
  return SEVERITY[String(value).trim().toLowerCase()] ?? "moderate";
}

function normalizeConfidence(value) {
  if (value === null || value === undefined || typeof value === "boolean") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function relativePath(path, worktree) {
  if (!path) return "";
  let normalized = String(path).trim().replace(/^`+|`+$/g, "");
  if (worktree && normalized.startsWith(worktree)) {
    normalized = normalized.slice(worktree.length).replace(/^\/+/, "");
  }
  return normalized;
}

function integerOrZero(value) {
  if (value === null || value === undefined || value === "") return 0;
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === "boolean") return value ? 1 : 0;
  if (typeof value === "string" && /^[+-]?\d+$/.test(value.trim())) return Number(value);
  throw new TypeError(`finding line is not an integer: ${JSON.stringify(value)}`);
}

function finding(member, values = {}) {
  const lineStart = integerOrZero(values.line_start);
  return {
    file: values.file ?? "",
    line_start: lineStart,
    line_end: integerOrZero(values.line_end || lineStart),
    category: values.category ?? "",
    severity: normalizeSeverity(values.severity),
    title: values.title ?? "",
    claim: values.claim ?? "",
    failure_scenario: values.failure_scenario ?? "",
    evidence: values.evidence ?? "",
    confidence: normalizeConfidence(values.confidence),
    _member: member,
  };
}

function mapDcrFindings(findings, member, worktree) {
  return findings.filter((entry) => entry && typeof entry === "object" && !Array.isArray(entry))
    .map((entry) => finding(member, {
      file: relativePath(entry.file ?? "", worktree),
      line_start: entry.line_start ?? 0,
      line_end: entry.line_end ?? 0,
      category: entry.category ?? "",
      severity: entry.severity ?? "",
      title: entry.title ?? "",
      claim: entry.claim ?? "",
      failure_scenario: entry.failure_scenario ?? "",
      evidence: entry.evidence ?? "",
      confidence: entry.confidence,
    }));
}

function mapCodexFindings(findings, member, worktree) {
  return findings.filter((entry) => entry && typeof entry === "object" && !Array.isArray(entry))
    .map((entry) => {
      const location = entry.code_location ?? {};
      const range = location.line_range ?? {};
      const priority = entry.priority;
      const body = entry.body || entry.claim || "";
      return finding(member, {
        file: relativePath(location.absolute_file_path || entry.file || "", worktree),
        line_start: range.start ?? entry.line_start ?? 0,
        line_end: range.end ?? entry.line_end ?? 0,
        category: entry.category ?? "",
        severity: priority !== null && priority !== undefined
          ? CODEX_PRIORITY[priority]
          : normalizeSeverity(entry.severity),
        title: String(entry.title ?? "").replace(/^\[P\d\]\s*/, ""),
        claim: String(body).split("\n")[0].slice(0, 400),
        failure_scenario: entry.failure_scenario ?? "",
        evidence: entry.body || entry.evidence || "",
        confidence: entry.confidence_score ?? entry.confidence,
      });
    });
}

function mapJsonDocument(document, member, worktree) {
  const findings = Array.isArray(document)
    ? document
    : document && typeof document === "object" ? document.findings : null;
  if (!Array.isArray(findings) || findings.length === 0) {
    return document && typeof document === "object" && !Array.isArray(document)
      && Object.hasOwn(document, "findings") ? [] : null;
  }
  const items = findings.filter((entry) => entry && typeof entry === "object" && !Array.isArray(entry));
  if (items.length === 0) return null;
  const codex = (!Array.isArray(document) && Object.hasOwn(document, "overall_correctness"))
    || items.some((entry) => Object.hasOwn(entry, "code_location"));
  if (codex) return mapCodexFindings(findings, member, worktree);
  if (items.some((entry) => Object.hasOwn(entry, "file"))) {
    return mapDcrFindings(findings, member, worktree);
  }
  return null;
}

function fromJson(text, member, worktree) {
  const candidates = [];
  const trimmed = text.trim();
  if (trimmed.startsWith("{") || trimmed.startsWith("[")) candidates.push(trimmed);
  for (const match of text.matchAll(JSON_FENCE_RE)) candidates.push(match[1]);
  for (const candidate of candidates) {
    let document;
    try {
      document = JSON.parse(candidate);
    } catch {
      continue;
    }
    const mapped = mapJsonDocument(document, member, worktree);
    if (mapped !== null) return mapped;
  }
  return null;
}

function lineField(fields) {
  const raw = String(fields.line || fields.lines || "").trim().replace(/^`|`$/g, "").trim();
  const match = raw ? raw.match(LINE_FIELD_RE) : null;
  if (!match) return [0, 0];
  const ends = [Number(match[1]), Number(match[2] ?? match[1])]
    .filter((value) => value >= 1)
    .sort((left, right) => left - right);
  return ends.length ? [ends[0], ends[ends.length - 1]] : [0, 0];
}

function anchor(fields, heading) {
  const fileReference = String(fields.file ?? "").trim().replace(/^`|`$/g, "").trim();
  if (fileReference) {
    const match = fileReference.match(FIELD_ANCHOR_RE);
    if (match) return [match[1].trim(), Number(match[2]), Number(match[3] ?? match[2])];
    const [lineStart, lineEnd] = lineField(fields);
    return [fileReference, lineStart, lineEnd];
  }
  const match = String(heading ?? "").match(INLINE_ANCHOR_RE);
  return match ? [match[1], Number(match[2]), Number(match[3] ?? match[2])] : null;
}

function firstSentence(value) {
  const text = String(value ?? "").trim();
  if (!text) return "";
  return (text.split(/(?<=[.!?])\s/, 1)[0] ?? "").slice(0, 80);
}

function fenceMask(lines) {
  const mask = Array(lines.length).fill(false);
  let delimiter = "";
  let width = 0;
  let openedAt = -1;
  lines.forEach((raw, index) => {
    const match = raw.trimStart().match(FENCE_DELIMITER_RE);
    if (delimiter) {
      mask[index] = true;
      if (match && match[1][0] === delimiter && match[1].length >= width && !match[2].trim()) {
        delimiter = "";
        width = 0;
        openedAt = -1;
      }
    } else if (match) {
      if (match[1][0] === "`" && match[2].includes("`")) return;
      delimiter = match[1][0];
      width = match[1].length;
      openedAt = index;
      mask[index] = true;
    }
  });
  if (delimiter) {
    for (let index = openedAt; index < lines.length; index += 1) mask[index] = false;
  }
  return mask;
}

function splitBlocks(text) {
  const lines = text.split(/\r?\n/);
  const fenced = fenceMask(lines);
  const blocks = [];
  let body = [];
  let heading = null;
  lines.forEach((line, index) => {
    const match = fenced[index] ? null : line.match(HEADING_RE);
    if (match) {
      if (body.length || heading !== null) blocks.push([heading, body]);
      heading = match[1].trim();
      body = [];
    } else {
      body.push([line, fenced[index]]);
    }
  });
  if (body.length || heading !== null) blocks.push([heading, body]);
  return blocks;
}

function fromProse(text, member, worktree) {
  const output = [];
  for (const [heading, body] of splitBlocks(text)) {
    if (heading === null) continue;
    const blob = body.map(([line]) => line).join("\n");
    const fields = {};
    for (const [line, inFence] of body) {
      if (inFence) continue;
      const match = line.match(FIELD_RE);
      if (match) fields[match[1].toLowerCase()] = match[2].trim().replace(/^\*+|\*+$/g, "").trim();
    }
    const codeAnchor = anchor(fields, heading);
    if (!codeAnchor) continue;

    let severity = fields.severity ?? "";
    let confidence = null;
    const combined = blob.match(SEVERITY_CONFIDENCE_RE);
    if (combined) {
      severity = combined[1];
      confidence = Math.round((Number(combined[2]) / 10) * 100) / 100;
    }

    let title = heading;
    const bracketed = title.match(/^\[(\w+)\]\s*(.*)$/);
    if (bracketed) {
      severity ||= bracketed[1];
      title = bracketed[2];
    }
    title = title.replace(/^(Issue|Alert\s*\d+|Vuln\s*\d+)\s*:?\s*/i, "").trim();
    let category = fields.category ?? "";
    const categoryMatch = title.match(/^([\w-]+):\s*`?/);
    if (!category && categoryMatch && heading.includes(":") && /\d/.test(heading)) {
      category = categoryMatch[1];
      title = title.slice(categoryMatch[0].length).replace(/^[ :`]+|[ :`]+$/g, "");
    }
    if (!Object.hasOwn(fields, "file")) {
      title = title.replace(INLINE_ANCHOR_RE, "").replace(/^[ :`\-—–]+|[ :`\-—–]+$/g, "");
    }

    const claim = fields.claim || fields.problem || fields.description || "";
    const failureScenario = fields.failure || fields["exploit scenario"] || "";
    const evidence = fields.evidence || fields.recommendation || fields["suggested fix"] || "";
    if (fields.confidence && confidence === null) {
      const match = fields.confidence.match(/[\d.]+/);
      if (match) {
        const parsed = Number(match[0]);
        if (Number.isFinite(parsed)) {
          confidence = Math.round((parsed > 1 ? parsed / 10 : parsed) * 100) / 100;
        }
      }
    }
    output.push(finding(member, {
      file: relativePath(codeAnchor[0], worktree),
      line_start: codeAnchor[1],
      line_end: codeAnchor[2],
      category,
      severity,
      title: title || firstSentence(claim) || "(untitled)",
      claim,
      failure_scenario: failureScenario,
      evidence,
      confidence,
    }));
  }
  return output;
}

function parseReviewMember({ member, text, worktree = "" }) {
  const jsonFindings = fromJson(text, member, worktree);
  if (jsonFindings !== null) return { findings: jsonFindings, strategy: "json" };
  if (NOISE_RE.test(text) && !text.toLowerCase().includes("**file:**") && !text.includes("```json")) {
    return { findings: [], strategy: "noise" };
  }
  return { findings: fromProse(text, member, worktree), strategy: "prose" };
}

function hasSubstance(entry) {
  return ["claim", "failure_scenario", "evidence"]
    .some((key) => String(entry[key] ?? "").trim());
}

function normalizeFindingPool(members, { worktree = "" } = {}) {
  const pool = [];
  const diagnostics = [];
  const gutted = [];
  for (const source of [...members].sort((left, right) => compareStrings(left.member, right.member))) {
    const { findings, strategy } = parseReviewMember({
      member: source.member,
      text: source.text,
      worktree,
    });
    pool.push(...findings);
    const bare = findings.filter((entry) => !hasSubstance(entry)).length;
    let status = "ok";
    if (!findings.length && strategy !== "noise" && new TextEncoder().encode(source.text).length > 40) {
      status = "warning";
    } else if (findings.length >= 2 && bare * 2 > findings.length) {
      status = "gutted";
      gutted.push({ member: source.member, bare, total: findings.length });
    } else if (bare) {
      status = "anchor-only";
    }
    diagnostics.push({ member: source.member, strategy, findings: findings.length, bare, status });
  }
  pool.sort((left, right) =>
    compareStrings(left.file, right.file)
    || left.line_start - right.line_start
    || left.line_end - right.line_end
    || compareStrings(String(left.title), String(right.title))
    || compareStrings(String(left.claim), String(right.claim))
    || compareStrings(left._member, right._member));
  pool.forEach((entry, index) => {
    entry.idx = index;
  });
  return { pool, diagnostics, gutted };
}

function compareStrings(left, right) {
  const leftPoints = Array.from(String(left), (character) => character.codePointAt(0));
  const rightPoints = Array.from(String(right), (character) => character.codePointAt(0));
  const length = Math.min(leftPoints.length, rightPoints.length);
  for (let index = 0; index < length; index += 1) {
    if (leftPoints[index] !== rightPoints[index]) return leftPoints[index] - rightPoints[index];
  }
  return leftPoints.length - rightPoints.length;
}

function requireHealthyFindingPool(result) {
  if (result.gutted.length) {
    const members = result.gutted
      .map(({ member, bare, total }) => `${member} (${bare}/${total})`)
      .join(", ");
    const error = new Error(`finding normalization rejected anchor-only member output: ${members}`);
    error.name = "FindingNormalizationError";
    error.code = "DEEP_FINDING_NORMALIZATION_GUTTED";
    error.details = result.gutted;
    throw error;
  }
  return result.pool;
}
return Object.freeze({ parseReviewMember, normalizeFindingPool, requireHealthyFindingPool });
})();

const Control = (() => {
/**
 * Deterministic Deep review control stages.
 *
 * These functions are workload code bundled into the native OWS. The Python
 * scripts remain migration oracles only.
 */

const SEVERITY_RANK = Object.freeze({ critical: 3, moderate: 2, nit: 1, "": 0 });
const SEVERITY_ORDER = Object.freeze({ critical: 0, moderate: 1, nit: 2, "": 3 });
const STATUS_ORDER = Object.freeze({ CONFIRMED: 0, UNCERTAIN: 1, REJECTED: 2 });
const VALID_VERDICTS = new Set(["VALID_FINDING", "TRUE_POSITIVE"]);
const INVALID_VERDICTS = new Set(["INVALID_FINDING", "FALSE_POSITIVE"]);
const CANDIDATE_KEYS = new Set([
  "cand_id", "file", "line_start", "line_end", "severity", "category", "title",
  "claim", "failure_scenario", "evidence", "confidence", "group_label", "root_cause",
  "detected_by", "detection_count", "merge_notes", "split_index", "variants",
]);
const CITED_FILE_RE = /[\w./-]*[A-Za-z_][\w./-]*\.(?:py|rs|ts|tsx|js|jsx|mjs|cjs|md|json|toml|yml|yaml|sh|bash|go|java|kt|cs|rb|c|h|cc|cpp|hpp|txt|tsv|csv|sql|css|scss|html|xml|ini|cfg|proto|lock)\b/g;

class ControlContractError extends Error {
  constructor(message, details = []) {
    super(message);
    this.name = "ControlContractError";
    this.code = "DEEP_CONTROL_CONTRACT_INVALID";
    this.details = details;
  }
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isFiniteNumber(value) {
  return typeof value === "number" && Number.isFinite(value);
}

function stableJson(value) {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(",")}]`;
  if (isObject(value)) {
    return `{${Object.keys(value).sort().map((key) =>
      `${JSON.stringify(key)}:${stableJson(value[key])}`).join(",")}}`;
  }
  return JSON.stringify(value);
}

function sameJson(left, right) {
  return stableJson(left) === stableJson(right);
}

function lexicalCompare(left, right) {
  const leftString = String(left);
  const rightString = String(right);
  return leftString < rightString ? -1 : leftString > rightString ? 1 : 0;
}

function sortedStrings(values) {
  return [...values].sort(lexicalCompare);
}

function basename(path) {
  const parts = String(path).split(/[\\/]/);
  return parts[parts.length - 1].toLowerCase();
}

function citedFiles(text) {
  if (typeof text !== "string") return new Set();
  return new Set([...text.matchAll(CITED_FILE_RE)].map((match) => basename(match[0])));
}

function variantFromPool(source) {
  const variant = {};
  for (const [key, value] of Object.entries(source)) {
    if (key !== "_member") variant[key] = value;
  }
  variant.member = source._member;
  return variant;
}

function setEquals(actual, expected) {
  if (actual.size !== expected.size) return false;
  return [...actual].every((entry) => expected.has(entry));
}

function aggregateToolkitFindings(roles, documents) {
  const severityOrder = { critical: 0, moderate: 1, nit: 2 };
  return documents.flatMap((document, index) => document.findings.map((finding) => ({
    ...finding,
    category: `${finding.category || "review"} (${roles[index]})`,
  }))).sort((left, right) =>
    (severityOrder[left.severity] ?? 3) - (severityOrder[right.severity] ?? 3));
}

function collateAreaFindings(areaResults) {
  const byKey = new Map();
  [...areaResults].sort((left, right) => lexicalCompare(left.area_id, right.area_id))
    .forEach((document) => {
      document.findings.forEach((finding) => {
        const key = [
          finding.file,
          finding.line_start,
          finding.line_end,
          finding.category,
          finding.claim,
        ].join("\u0000");
        const current = byKey.get(key);
        if (current === undefined
            || String(finding.evidence).length > String(current.evidence).length) {
          byKey.set(key, finding);
        }
      });
    });
  const severityOrder = { critical: 0, moderate: 1, nit: 2 };
  return [...byKey.values()].sort((left, right) =>
    (right.confidence ?? 0) - (left.confidence ?? 0)
    || (severityOrder[left.severity] ?? 3) - (severityOrder[right.severity] ?? 3)
    || lexicalCompare(left.file, right.file)
    || left.line_start - right.line_start);
}

function validateCandidateLedger(document, pool) {
  const errors = [];
  if (!Array.isArray(pool)) {
    throw new ControlContractError("candidate pool must be an array", ["pool: expected a JSON array of findings"]);
  }

  const byIndex = new Map();
  pool.forEach((source, position) => {
    if (!isObject(source)) {
      errors.push(`pool[${position}]: expected an object`);
      return;
    }
    if (!Number.isInteger(source.idx)) {
      errors.push(`pool[${position}]: idx must be an integer`);
      return;
    }
    if (byIndex.has(source.idx)) {
      errors.push(`pool[${position}]: duplicate idx ${source.idx}`);
      return;
    }
    if (!Object.hasOwn(SEVERITY_RANK, source.severity)) {
      errors.push(`pool idx ${source.idx}: unsupported severity ${JSON.stringify(source.severity)}`);
    }
    if (!Object.hasOwn(source, "_member")) {
      errors.push(`pool idx ${source.idx}: missing _member`);
    }
    if (source.confidence !== null && !isFiniteNumber(source.confidence)) {
      errors.push(`pool idx ${source.idx}: confidence must be a finite number or null`);
    }
    byIndex.set(source.idx, source);
  });

  const topLevelKeys = isObject(document) ? new Set(Object.keys(document)) : new Set();
  const expectedTopLevel = new Set(["candidates", "n_findings", "n_candidates"]);
  if (!isObject(document) || !setEquals(topLevelKeys, expectedTopLevel)) {
    errors.push("candidates: top-level keys must be exactly candidates/n_findings/n_candidates");
    throw new ControlContractError("candidate ledger is invalid", errors);
  }
  if (!Array.isArray(document.candidates)) {
    errors.push("candidates: candidates must be an array");
    throw new ControlContractError("candidate ledger is invalid", errors);
  }
  if (document.n_findings !== pool.length) {
    errors.push(`n_findings is ${document.n_findings}, pool holds ${pool.length}`);
  }
  if (document.n_candidates !== document.candidates.length) {
    errors.push(`n_candidates is ${document.n_candidates}, ledger holds ${document.candidates.length}`);
  }

  const seen = new Set();
  const owners = new Map();
  const families = new Map();
  const ordering = [];
  let grouped = 0;
  let multiMember = 0;

  document.candidates.forEach((candidate, position) => {
    const candidateId = isObject(candidate) ? candidate.cand_id ?? `#${position}` : `#${position}`;
    if (!isObject(candidate)) {
      errors.push(`${candidateId}: expected an object`);
      return;
    }
    if (!setEquals(new Set(Object.keys(candidate)), CANDIDATE_KEYS)) {
      errors.push(`${candidateId}: candidate schema is not exact`);
      return;
    }
    if (candidate.cand_id !== `K${String(position).padStart(3, "0")}`) {
      errors.push(`${candidateId}: cand_id must match ledger position`);
    }
    if (!Object.hasOwn(SEVERITY_RANK, candidate.severity)) {
      errors.push(`${candidateId}: unsupported severity ${JSON.stringify(candidate.severity)}`);
    }
    if (!Number.isInteger(candidate.line_start) || !Number.isInteger(candidate.line_end)
        || candidate.line_start < 1 || candidate.line_start > candidate.line_end) {
      errors.push(`${candidateId}: anchor range is invalid`);
    }
    if (!Number.isInteger(candidate.split_index) || candidate.split_index < 0) {
      errors.push(`${candidateId}: split_index must be an integer >= 0`);
    }
    if (typeof candidate.merge_notes !== "string" || !candidate.merge_notes.trim()) {
      errors.push(`${candidateId}: merge_notes must be non-empty`);
    }
    if (!Array.isArray(candidate.variants) || candidate.variants.length === 0
        || candidate.variants.some((variant) => !isObject(variant) || !Number.isInteger(variant.idx))) {
      errors.push(`${candidateId}: variants must be a non-empty array of indexed pool entries`);
      return;
    }

    const indexes = candidate.variants.map((variant) => variant.idx);
    const normalizedIndexes = [...new Set(indexes)].sort((left, right) => left - right);
    if (!sameJson(indexes, normalizedIndexes)) {
      errors.push(`${candidateId}: variants must be unique and ordered by idx`);
    }
    if (indexes.some((index) => !byIndex.has(index))) {
      errors.push(`${candidateId}: variants cite an unknown pool idx`);
      return;
    }
    candidate.variants.forEach((variant) => {
      if (!sameJson(variant, variantFromPool(byIndex.get(variant.idx)))) {
        errors.push(`${candidateId}: variant idx ${variant.idx} is not its pool entry verbatim`);
      }
    });

    const familyKey = indexes.join(",");
    const family = families.get(familyKey) ?? [];
    family.push(candidate);
    families.set(familyKey, family);
    ordering.push([indexes, candidate.split_index]);
    if (indexes.length > 1) grouped += 1;
    indexes.forEach((index) => {
      seen.add(index);
      const priorOwner = owners.get(index);
      if (priorOwner !== undefined && priorOwner !== familyKey) {
        errors.push(`pool idx ${index} appears in two different candidate families`);
      } else {
        owners.set(index, familyKey);
      }
    });

    const members = sortedStrings(new Set(indexes.map((index) => byIndex.get(index)._member)));
    if (!sameJson(candidate.detected_by, members)) {
      errors.push(`${candidateId}: detected_by must equal sorted distinct variant members`);
    }
    if (candidate.detection_count !== members.length) {
      errors.push(`${candidateId}: detection_count must equal detected_by length`);
    }
    if (members.length > 1) multiMember += 1;
    const expectedSeverity = indexes
      .map((index) => byIndex.get(index).severity)
      .reduce((left, right) => SEVERITY_RANK[right] > SEVERITY_RANK[left] ? right : left, "");
    if (candidate.severity !== expectedSeverity) {
      errors.push(`${candidateId}: severity must be the group maximum`);
    }
    const confidences = indexes
      .map((index) => byIndex.get(index).confidence)
      .filter((value) => value !== null);
    const expectedConfidence = confidences.length ? Math.max(...confidences) : null;
    if (candidate.confidence !== expectedConfidence) {
      errors.push(`${candidateId}: confidence must be the maximum non-null variant confidence`);
    }
    for (const field of ["title", "claim", "failure_scenario", "evidence"]) {
      if (typeof candidate[field] !== "string") {
        errors.push(`${candidateId}: ${field} must be a string`);
      } else if (!candidate[field].trim()
        && indexes.some((index) => String(byIndex.get(index)[field] ?? "").trim())) {
        errors.push(`${candidateId}: ${field} drops source text`);
      }
    }
    const categories = new Set(indexes.map((index) => String(byIndex.get(index).category ?? "")));
    if ([...categories].some(Boolean) && !categories.has(String(candidate.category ?? ""))) {
      errors.push(`${candidateId}: category came from no variant`);
    }
  });

  const dropped = [...byIndex.keys()].filter((index) => !seen.has(index)).sort((a, b) => a - b);
  if (dropped.length) errors.push(`pool idx ${dropped.join(",")} reach no candidate`);

  for (const [familyKey, family] of families) {
    const indexes = familyKey.split(",").map(Number);
    const splitIndexes = family.map((candidate) => candidate.split_index).sort((a, b) => a - b);
    if (!sameJson(splitIndexes, family.map((_, index) => index))) {
      errors.push(`source ${familyKey}: split_index values must be contiguous from zero`);
    }
    if (indexes.length === 1) {
      const source = byIndex.get(indexes[0]);
      for (const candidate of family) {
        const fields = family.length > 1
          ? ["category", "file"]
          : ["category", "file", "title", "claim", "failure_scenario", "evidence"];
        for (const field of fields) {
          if (String(candidate[field] ?? "") !== String(source[field] ?? "")) {
            errors.push(`${candidate.cand_id}: singleton ${field} was rewritten`);
          }
        }
      }
    }
    if (family.length === 1) {
      const sourceTitles = new Set(indexes.map((index) => String(byIndex.get(index).title ?? "")));
      if ([...sourceTitles].some((title) => title.trim())
          && !sourceTitles.has(String(family[0].title ?? ""))) {
        errors.push(`${family[0].cand_id}: title was authored despite a source title`);
      }
    }
    const requiredCitations = new Set();
    indexes.forEach((index) => citedFiles(byIndex.get(index).evidence)
      .forEach((file) => requiredCitations.add(file)));
    const retainedCitations = new Set();
    family.forEach((candidate) => citedFiles([
      candidate.evidence, candidate.claim, candidate.failure_scenario, candidate.file,
    ].join(" ")).forEach((file) => retainedCitations.add(file)));
    const missing = [...requiredCitations].filter((file) => !retainedCitations.has(file));
    if (missing.length) errors.push(`${family.map((candidate) => candidate.cand_id)} drop source citations`);
  }

  const sortedOrdering = [...ordering].sort((left, right) => {
    const common = Math.min(left[0].length, right[0].length);
    for (let index = 0; index < common; index += 1) {
      if (left[0][index] !== right[0][index]) return left[0][index] - right[0][index];
    }
    return left[0].length - right[0].length || left[1] - right[1];
  });
  if (!sameJson(ordering, sortedOrdering)) {
    errors.push("candidates must be ordered by variant idx tuple and split_index");
  }
  if (errors.length) throw new ControlContractError("candidate ledger is invalid", errors);
  return {
    n_pool: pool.length,
    n_cand: document.candidates.length,
    grouped,
    split: [...families.values()].filter((family) => family.length > 1).length,
    multi_member: multiMember,
  };
}

function groupVerificationUnits(document, bundleSizes = {}) {
  if (!isObject(document) || !Array.isArray(document.candidates)) {
    throw new ControlContractError("candidate document must contain candidates");
  }
  const bundleSize = (name, fallback) => {
    const value = bundleSizes[name];
    if (value === undefined || value === null || !Number.isInteger(value)) return fallback;
    return value > 0 ? value : 0;
  };
  const sizes = {
    critical: bundleSize("critical", 1),
    moderate: bundleSize("moderate", 2),
    nit: bundleSize("nit", 0),
  };
  const tiers = [
    ["critical", new Set(["critical"])],
    ["moderate", new Set(["moderate"])],
    ["nit", new Set(["nit", ""])],
  ];
  const units = [];
  for (const [tier, severities] of tiers) {
    const candidates = document.candidates
      .filter((candidate) => severities.has(String(candidate.severity ?? "").toLowerCase()))
      .sort((left, right) =>
        (SEVERITY_ORDER[String(left.severity ?? "").toLowerCase()] ?? 3)
        - (SEVERITY_ORDER[String(right.severity ?? "").toLowerCase()] ?? 3)
        || lexicalCompare(left.file ?? "", right.file ?? "")
        || Number(left.line_start ?? 0) - Number(right.line_start ?? 0)
        || lexicalCompare(left.cand_id ?? "", right.cand_id ?? ""));
    const size = sizes[tier] <= 0 ? candidates.length : sizes[tier];
    for (let offset = 0; offset < candidates.length; offset += size) {
      const group = candidates.slice(offset, offset + size);
      units.push({
        unit_id: `U${String(units.length).padStart(3, "0")}`,
        severity_tier: tier,
        cand_ids: group.map((candidate) => candidate.cand_id),
        candidates: group,
      });
    }
  }
  return {
    units,
    n_units: units.length,
    n_candidates: document.candidates.length,
    policy: { bundle_sizes: sizes, note: "0 = one unit for the whole tier" },
    unit_counts_by_tier: Object.fromEntries(tiers.map(([tier]) => [
      tier, units.filter((unit) => unit.severity_tier === tier).length,
    ])),
  };
}

function reconcileUnitJudgments(unitsDocument, unitJudgments) {
  if (!isObject(unitsDocument) || !Array.isArray(unitsDocument.units) || !Array.isArray(unitJudgments)) {
    throw new ControlContractError("units and unit judgments must be arrays");
  }
  const expected = new Map();
  unitsDocument.units.forEach((unit) => {
    if (!isObject(unit) || !Array.isArray(unit.cand_ids)) return;
    unit.cand_ids.forEach((candidateId) => expected.set(candidateId, unit.unit_id));
  });
  const judgments = {};
  const diagnostics = { bad: [], duplicates: [], unknown: [], wrongUnit: [] };
  for (const document of unitJudgments) {
    if (!isObject(document)) {
      diagnostics.bad.push({ unit_id: null, cand_id: null, verdict: null });
      continue;
    }
    const unitId = document.unit_id;
    const judgeId = document.judge_id ?? "j0";
    const verdicts = Array.isArray(document.verdicts) ? document.verdicts : [];
    for (const verdict of verdicts) {
      const candidateId = isObject(verdict) ? verdict.cand_id : null;
      const decision = isObject(verdict) ? verdict.verdict : null;
      if (!candidateId || (!VALID_VERDICTS.has(decision) && !INVALID_VERDICTS.has(decision))) {
        diagnostics.bad.push({ unit_id: unitId, cand_id: candidateId, verdict: decision });
      } else if (!expected.has(candidateId)) {
        diagnostics.unknown.push(candidateId);
      } else if (expected.get(candidateId) !== unitId) {
        diagnostics.wrongUnit.push(candidateId);
      } else if (Object.hasOwn(judgments, candidateId)) {
        diagnostics.duplicates.push(candidateId);
      } else {
        const ruling = {
          judge_id: judgeId,
          cand_id: candidateId,
          verdict: decision,
          which_advocate_won: verdict.which_advocate_won ?? "",
          unit_id: unitId,
        };
        for (const field of ["decisive_fact", "independent_code_check", "reasoning"]) {
          if (verdict[field] !== null && verdict[field] !== undefined) ruling[field] = verdict[field];
        }
        judgments[candidateId] = ruling;
      }
    }
  }
  diagnostics.missing = [...expected.keys()]
    .filter((candidateId) => !Object.hasOwn(judgments, candidateId))
    .sort();
  diagnostics.missingUnits = sortedStrings(new Set(
    diagnostics.missing.map((candidateId) => expected.get(candidateId)),
  ));
  return { judgments, diagnostics };
}

function requireCompleteJudgments(unitsDocument, unitJudgments) {
  const reconciled = reconcileUnitJudgments(unitsDocument, unitJudgments);
  const { diagnostics } = reconciled;
  if (Object.values(diagnostics).some((entries) => entries.length > 0)) {
    throw new ControlContractError("judgment reconciliation is incomplete", diagnostics);
  }
  return reconciled.judgments;
}

function winningVerdict(verdicts) {
  const valid = verdicts.filter((verdict) => VALID_VERDICTS.has(verdict.verdict)).length;
  const invalid = verdicts.filter((verdict) => INVALID_VERDICTS.has(verdict.verdict)).length;
  if (valid > invalid) return "VALID_FINDING";
  if (invalid > valid) return "INVALID_FINDING";
  return null;
}

function synthesizeReview(candidateDocument, judgments) {
  if (!isObject(candidateDocument) || !Array.isArray(candidateDocument.candidates)) {
    throw new ControlContractError("candidate document must contain candidates");
  }
  const byCandidate = Array.isArray(judgments)
    ? judgments.reduce((groups, judgment) => {
      if (isObject(judgment)) {
        const group = groups.get(judgment.cand_id) ?? [];
        group.push(judgment);
        groups.set(judgment.cand_id, group);
      }
      return groups;
    }, new Map())
    : new Map(Object.entries(judgments ?? {}).map(([candidateId, value]) => [
      candidateId, Array.isArray(value) ? value : [value],
    ]));
  const rows = candidateDocument.candidates.map((candidate) => {
    const verdicts = byCandidate.get(candidate.cand_id) ?? [];
    const judgeVerdict = winningVerdict(verdicts);
    const status = judgeVerdict === "VALID_FINDING"
      ? "CONFIRMED"
      : judgeVerdict === "INVALID_FINDING" ? "REJECTED" : "UNCERTAIN";
    return {
      ...candidate,
      status,
      judge_verdict: judgeVerdict ?? "none",
      which_advocate_won: verdicts.find((verdict) => verdict.which_advocate_won)?.which_advocate_won ?? "",
      n_judges: verdicts.length,
    };
  }).sort((left, right) =>
    STATUS_ORDER[left.status] - STATUS_ORDER[right.status]
    || (SEVERITY_ORDER[left.severity] ?? 3) - (SEVERITY_ORDER[right.severity] ?? 3)
    || lexicalCompare(left.file, right.file)
    || left.line_start - right.line_start);
  const summary = Object.fromEntries(["CONFIRMED", "REJECTED", "UNCERTAIN"]
    .map((status) => [status, rows.filter((row) => row.status === status).length]));
  return { rows, summary, reportMarkdown: renderReport(candidateDocument, rows, summary) };
}

function renderReport(candidateDocument, rows, summary) {
  const lines = [
    "# Deep Code Review — report",
    "",
    `CONFIRMED ${summary.CONFIRMED} | REJECTED ${summary.REJECTED} | UNCERTAIN ${summary.UNCERTAIN}  (from ${candidateDocument.n_findings ?? "?"} raw findings across the enabled member roster; ${candidateDocument.n_candidates ?? "?"} distinct candidates, each judged by an adversarial valid-vs-false-alarm advocate debate)`,
    "",
    `## Confirmed findings (${summary.CONFIRMED}) — judged valid, by severity`,
    "",
  ];
  const emit = (candidate) => {
    const members = candidate.detected_by?.join(", ") || "?";
    lines.push(`#### ${candidate.file}:${candidate.line_start}-${candidate.line_end} — ${candidate.title}`);
    lines.push(`*severity:* ${candidate.severity ?? ""} | *category:* ${candidate.category ?? ""} | *found by:* ${candidate.detection_count ?? "?"} member(s) [${members}] | *judge:* ${candidate.judge_verdict ?? "none"} (advocate ${candidate.which_advocate_won || "?"} won)`);
    const confidence = (candidate.variants ?? [])
      .filter((variant) => variant.confidence !== null && variant.confidence !== undefined)
      .map((variant) => `${variant.member ?? "?"} ${variant.confidence}`);
    if (confidence.length) lines.push(`*reviewer confidence:* ${confidence.join(" | ")}`);
    if (candidate.group_label) lines.push(`*finding:* ${candidate.group_label}`);
    lines.push("", `**Claim:** ${candidate.claim ?? ""}`, "", `**Failure scenario:** ${candidate.failure_scenario ?? ""}`, "", `**Evidence:** ${candidate.evidence ?? ""}`, "");
  };
  const emitBySeverity = (candidates) => {
    const labels = { critical: "Critical", moderate: "Moderate", nit: "Nit", "": "Unspecified severity" };
    for (const severity of ["critical", "moderate", "nit", ""]) {
      const matching = candidates.filter((candidate) => (candidate.severity || "") === severity);
      if (!matching.length) continue;
      lines.push(`### ${labels[severity]} (${matching.length})`, "");
      matching.forEach(emit);
    }
  };
  const confirmed = rows.filter((candidate) => candidate.status === "CONFIRMED");
  if (!confirmed.length) lines.push("_none_", "");
  emitBySeverity(confirmed);
  const uncertain = rows.filter((candidate) => candidate.status === "UNCERTAIN");
  if (uncertain.length) {
    lines.push(`## Uncertain (${uncertain.length}) — no decisive ruling; not posted`, "");
    uncertain.forEach(emit);
  }
  return `${lines.join("\n")}\n`;
}
return Object.freeze({ ControlContractError, aggregateToolkitFindings, collateAreaFindings, validateCandidateLedger, groupVerificationUnits, reconcileUnitJudgments, requireCompleteJudgments, synthesizeReview });
})();

const Post = (() => {
/**
 * Deterministic Deep review payload construction.
 *
 * This module builds the payload only. Credentialed application belongs to the
 * backend conditional-output boundary.
 */

const MAX_ANCHOR_SPAN = 4;
const MAX_REVIEW_BODY_BYTES = 262144;

function decodeGitQuotedPath(value) {
  const raw = String(value);
  if (!raw.startsWith("\"")) return raw;
  if (!raw.endsWith("\"") || raw.length < 2) {
    throw new TypeError("Git patch path has an unterminated quote");
  }
  const bytes = [];
  const literal = new TextEncoder();
  const escapes = Object.freeze({
    a: 0x07,
    b: 0x08,
    t: 0x09,
    n: 0x0a,
    v: 0x0b,
    f: 0x0c,
    r: 0x0d,
    "\"": 0x22,
    "\\": 0x5c,
  });
  for (let index = 1; index < raw.length - 1; index += 1) {
    const character = raw[index];
    if (character !== "\\") {
      bytes.push(...literal.encode(character));
      continue;
    }
    index += 1;
    if (index >= raw.length - 1) throw new TypeError("Git patch path has a trailing escape");
    const escaped = raw[index];
    if (Object.hasOwn(escapes, escaped)) {
      bytes.push(escapes[escaped]);
      continue;
    }
    if (!/[0-7]/.test(escaped)) {
      throw new TypeError(`Git patch path has unsupported escape \\${escaped}`);
    }
    let octal = escaped;
    while (octal.length < 3 && index + 1 < raw.length - 1 && /[0-7]/.test(raw[index + 1])) {
      index += 1;
      octal += raw[index];
    }
    const byte = Number.parseInt(octal, 8);
    if (byte > 0xff) throw new TypeError(`Git patch path has invalid octal escape \\${octal}`);
    bytes.push(byte);
  }
  return new TextDecoder("utf-8", { fatal: true }).decode(Uint8Array.from(bytes));
}

function boundedReviewBody(value, label) {
  const bytes = new TextEncoder().encode(value).length;
  if (bytes > MAX_REVIEW_BODY_BYTES) {
    throw new TypeError(`${label} exceeds ${MAX_REVIEW_BODY_BYTES} UTF-8 bytes`);
  }
  return value;
}

function parseDiffRightSide(text) {
  const valid = new Map();
  let path = null;
  let right = null;
  for (const line of String(text ?? "").split(/\r?\n/)) {
    if (line.startsWith("diff --git")) {
      path = null;
      right = null;
      continue;
    }
    if (line.startsWith("--- ")) continue;
    if (line.startsWith("+++ ")) {
      const declared = decodeGitQuotedPath(line.slice(4).trim());
      if (declared === "/dev/null") {
        path = null;
      } else {
        path = declared.startsWith("b/") ? declared.slice(2) : declared;
        if (!valid.has(path)) valid.set(path, new Set());
      }
      right = null;
      continue;
    }
    if (line.startsWith("@@")) {
      const match = line.match(/\+(\d+)/);
      right = match ? Number(match[1]) : null;
      continue;
    }
    if (path === null || right === null) continue;
    const tag = line[0] ?? "";
    if (tag === "+") {
      valid.get(path).add(right);
      right += 1;
    } else if (tag === "-") {
      continue;
    } else if (tag === "\\") {
      continue;
    } else if (tag === " ") {
      valid.get(path).add(right);
      right += 1;
    } else {
      right = null;
    }
  }
  return valid;
}

function anchorFor(candidate, valid, haveDiff) {
  const file = candidate.file;
  const lineStart = candidate.line_start;
  const lineEnd = candidate.line_end;
  if (!haveDiff) return null;
  const lines = valid.get(file) ?? new Set();
  if (lines.has(lineStart) && lines.has(lineEnd) && lineEnd > lineStart
      && lineEnd - lineStart + 1 <= MAX_ANCHOR_SPAN) {
    return {
      path: file,
      start_line: lineStart,
      start_side: "RIGHT",
      line: lineEnd,
      side: "RIGHT",
    };
  }
  const candidates = lineStart > 0 && lineStart <= lineEnd
    ? [Math.min(lineStart + MAX_ANCHOR_SPAN - 1, lineEnd), lineStart, lineEnd]
    : [lineStart, lineEnd];
  for (const line of candidates) {
    if (lines.has(line)) return { path: file, line, side: "RIGHT" };
  }
  return null;
}

function anchorCovers(location, candidate) {
  return (location.start_line ?? location.line) <= candidate.line_start
    && location.line >= candidate.line_end;
}

function declaredRange(candidate) {
  return candidate.line_end > candidate.line_start
    ? `${candidate.line_start}-${candidate.line_end}`
    : `${candidate.line_start}`;
}

function fieldValue(candidate, key) {
  const raw = candidate[key];
  if (raw === null || raw === undefined) return null;
  const text = typeof raw === "string" ? raw : String(raw);
  return text.trim() ? text : null;
}

function fieldLines(candidate, fields) {
  const output = [];
  for (const [label, key] of fields) {
    const value = fieldValue(candidate, key);
    if (value !== null) output.push(`**${label}:** ${value}`, "");
  }
  return output;
}

function roundHalfEven(value) {
  const floor = Math.floor(value);
  const fraction = value - floor;
  if (fraction < 0.5) return floor;
  if (fraction > 0.5) return floor + 1;
  return floor % 2 === 0 ? floor : floor + 1;
}

function formatInteger(value) {
  const digits = String(Math.trunc(Number(value)));
  const sign = digits.startsWith("-") ? "-" : "";
  const body = sign ? digits.slice(1) : digits;
  return `${sign}${body.replace(/\B(?=(\d{3})+(?!\d))/g, ",")}`;
}

function formatOneDecimal(value) {
  const tenths = roundHalfEven(Number(value) * 10);
  return `${Math.trunc(tenths / 10)}.${Math.abs(tenths % 10)}`;
}

function markerComment(marker) {
  const body = JSON.stringify(marker).replaceAll("-->", "-- >");
  return `<!-- deep-code-review:v1 ${body} -->`;
}

function candidateRoster(candidates) {
  const roster = new Set();
  for (const candidate of candidates) {
    for (const member of candidate.detected_by ?? []) roster.add(member);
  }
  return [...roster].sort();
}

function footerLine(totalAiu, actions = {}) {
  const server = String(actions.serverUrl ?? "").replace(/\/+$/, "");
  const repository = actions.repository ?? "";
  const runId = actions.runId ?? "";
  const costSuffix = totalAiu !== null && totalAiu !== undefined
    ? ` · ${formatOneDecimal(totalAiu)} AIC`
    : "";
  const label = server && repository && runId
    ? `[Deep Code Review](${server}/${repository}/actions/runs/${runId})`
    : "Deep Code Review";
  return `> Generated from ${label}${costSuffix}`;
}

function inlineCommentBody(candidate, anchorNote, actions) {
  const members = candidate.detected_by?.join(", ") || "?";
  const confidence = (candidate.variants ?? [])
    .filter((variant) => variant.confidence !== null && variant.confidence !== undefined)
    .map((variant) => `${variant.member ?? "?"} ${variant.confidence}`)
    .join(" | ");
  let metadata = `severity: ${candidate.severity || "unspecified"} · `
    + `category: ${candidate.category || "?"} · `
    + `found by: ${candidate.detection_count ?? "?"} member(s) [${members}] · `
    + `judge: ${candidate.judge_verdict ?? "none"} `
    + `(advocate ${candidate.which_advocate_won || "?"} won)`;
  if (confidence) metadata += ` · reviewer confidence: ${confidence}`;

  const parts = [`**${candidate.title}**`, ""];
  if (anchorNote) parts.push(anchorNote, "");
  parts.push(...fieldLines(candidate, [
    ["Claim", "claim"],
    ["Failure scenario", "failure_scenario"],
    ["Evidence", "evidence"],
  ]));
  parts.push(
    "<details><summary>metadata</summary>",
    "",
    metadata,
    "",
    "</details>",
    "",
    footerLine(null, actions),
  );
  return boundedReviewBody(parts.join("\n"), "inline review comment body");
}

function buildBody({
  owner,
  repo,
  inputs,
  counts,
  cost,
  marker,
  unanchored,
  threeDotBase,
  actions,
}) {
  const head = inputs.head || "";
  const base = threeDotBase || "";
  const shortHead = head ? head.slice(0, 10) : "(unknown)";
  const shortBase = base ? base.slice(0, 10) : "(unknown)";
  const costText = Object.hasOwn(cost, "total_aiu") && Object.hasOwn(cost, "total_tokens")
    ? ` Cost ~${formatInteger(roundHalfEven(Number(cost.total_aiu)))} AIU / `
      + `${formatInteger(cost.total_tokens)} tok.`
    : "";
  const posted = marker.posted_at || "";
  const postedText = posted.length >= 16 && posted.slice(10, 11) === "T"
    ? ` Posted ${posted.slice(0, 10)} ${posted.slice(11, 16)} UTC.`
    : "";
  const summary = `Reviewed **\`${owner}/${repo}@${shortHead}\`** against base `
    + `\`${shortBase}\` — **${counts.confirmed}** confirmed finding(s) `
    + `(${counts.uncertain} uncertain, not posted).${costText}${postedText}`;
  const lines = [markerComment(marker), "", "## Deep Code Review", "", summary];
  if (unanchored.length) {
    lines.push(
      "",
      `#### ${unanchored.length} confirmed finding(s) not anchored to the diff`,
      "",
    );
    for (const candidate of unanchored) {
      lines.push("", `- **${candidate.title}** (\`${candidate.file}:${candidate.line_start}\`)`);
      for (const [label, key] of [
        ["Claim", "claim"],
        ["Failure scenario", "failure_scenario"],
        ["Evidence", "evidence"],
      ]) {
        const value = fieldValue(candidate, key);
        if (value !== null) lines.push(`  - **${label}:** ${value}`);
      }
    }
  }
  lines.push("", "", footerLine(cost.total_aiu, actions));
  return boundedReviewBody(lines.join("\n"), "review body");
}

function constructReviewPayload({
  owner,
  repo,
  number,
  event = "COMMENT",
  commitId = null,
  confirmed,
  counts,
  inputs,
  cost = {},
  roster,
  runSlug,
  anchorDiff = "",
  threeDotBase = null,
  postedAt,
  actions = {},
}) {
  if (event !== "COMMENT") {
    throw new TypeError("native Deep reviews must use the neutral COMMENT event");
  }
  if (typeof postedAt !== "string"
      || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(postedAt)) {
    throw new TypeError("postedAt must be an injected UTC second timestamp");
  }
  const valid = parseDiffRightSide(anchorDiff);
  const haveDiff = valid.size > 0;
  const anchored = [];
  const unanchored = [];
  const comments = [];
  for (const candidate of confirmed) {
    const location = anchorFor(candidate, valid, haveDiff);
    if (location === null) {
      unanchored.push(candidate);
      continue;
    }
    let note = null;
    if (!anchorCovers(location, candidate)) {
      note = `_Reported at \`${candidate.file}:${declaredRange(candidate)}\`; anchored here on line `
        + `${location.line} because that range cannot be quoted inline._`;
    }
    anchored.push(candidate);
    comments.push({ ...location, body: inlineCommentBody(candidate, note, actions) });
  }

  const base = threeDotBase || inputs.base || "";
  const marker = {
    marker: "deep-code-review",
    v: 1,
    reviewed_head: inputs.head || "",
    reviewed_merge_base: base,
    base,
    repo: `${owner}/${repo}`,
    pr: number,
    posted_at: postedAt,
    findings: counts,
    roster,
    run: runSlug,
  };
  if (Object.keys(cost).length) marker.cost = cost;
  const body = buildBody({
    owner,
    repo,
    inputs,
    counts,
    cost,
    marker,
    unanchored,
    threeDotBase: base,
    actions,
  });
  const payload = { body, event };
  if (comments.length) payload.comments = comments;
  if (commitId) payload.commit_id = commitId;
  return { payload, anchored, unanchored, marker };
}
return Object.freeze({ decodeGitQuotedPath, parseDiffRightSide, markerComment, candidateRoster, constructReviewPayload });
})();

const Cost = (() => {
const TOP_LEVEL_KEYS = new Set([
  "usedTokens",
  "usedNanoAiu",
  "usedCredits",
  "creditStatus",
  "callCount",
  "calls",
]);
const CALL_KEYS = new Set([
  "callId",
  "label",
  "phase",
  "attribution",
  "model",
  "tokensIn",
  "tokensOut",
  "personaTokens",
  "nanoAiu",
  "creditStatus",
  "failed",
]);
const CREDIT_STATUSES = new Set(["reported", "unreported", "overflow"]);
const ATTRIBUTION_KEYS = new Set(["member", "role", "instance"]);
const ATTRIBUTION_STRING_MAX_LENGTH = 128;
const UNREPORTED_CREDIT_STATUS = "unreported";
const CANONICAL_SPECIALISTS = Object.freeze({
  "claude-code--pr-review-toolkit": Object.freeze({
    applicability: Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
    "code-reviewer": Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
    "pr-test-analyzer": Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
    "comment-analyzer": Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
    "silent-failure-hunter": Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
    "type-design-analyzer": Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
    "code-simplifier": Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
  }),
  "dynamic-review-areas": Object.freeze({
    "area-planner": Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
    "area-reviewer": Object.freeze({ category: "reviewer", phase: "Run Reviewers" }),
  }),
  "code-review--dedup-merge": Object.freeze({
    merge: Object.freeze({ category: "orchestrator", phase: "Merge Findings" }),
  }),
  "code-review--advocate--is-true-positive": Object.freeze({
    "true-positive-advocate": Object.freeze({
      category: "verification",
      phase: "Judge Findings",
    }),
  }),
  "code-review--advocate--is-false-positive": Object.freeze({
    "false-positive-advocate": Object.freeze({
      category: "verification",
      phase: "Judge Findings",
    }),
  }),
  "code-review--judge": Object.freeze({
    judge: Object.freeze({ category: "verification", phase: "Judge Findings" }),
  }),
});

class CostContractError extends Error {
  constructor(message, details = []) {
    super(message);
    this.name = "CostContractError";
    this.details = details;
  }
}

function fail(message, details = []) {
  throw new CostContractError(message, details);
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function exactKeys(value, allowed, path, errors) {
  for (const key of Object.keys(value)) {
    if (!allowed.has(key)) errors.push(`${path}.${key} is unknown`);
  }
  for (const key of allowed) {
    if (!Object.hasOwn(value, key)) errors.push(`${path}.${key} is missing`);
  }
}

function safeInteger(value, path, errors) {
  if (!Number.isSafeInteger(value) || value < 0) {
    errors.push(`${path} must be a non-negative safe integer`);
    return false;
  }
  return true;
}

function nonEmptyString(value, path, errors) {
  if (typeof value !== "string" || !value.length) {
    errors.push(`${path} must be a non-empty string`);
    return false;
  }
  return true;
}

function compareCodePointStrings(left, right) {
  const leftPoints = Array.from(String(left), (character) => character.codePointAt(0));
  const rightPoints = Array.from(String(right), (character) => character.codePointAt(0));
  const length = Math.min(leftPoints.length, rightPoints.length);
  for (let index = 0; index < length; index += 1) {
    if (leftPoints[index] !== rightPoints[index]) return leftPoints[index] - rightPoints[index];
  }
  return leftPoints.length - rightPoints.length;
}

function compareCalls(left, right) {
  return compareCodePointStrings(left.phase, right.phase)
    || compareCodePointStrings(left.label, right.label)
    || compareCodePointStrings(left.callId, right.callId);
}

function creditStatusFor(callCount, sawOverflow, sawUnreported, emptyStatus = UNREPORTED_CREDIT_STATUS) {
  if (callCount === 0) return emptyStatus;
  if (sawOverflow) return "overflow";
  if (sawUnreported) return UNREPORTED_CREDIT_STATUS;
  return "reported";
}

function canonicalAttribution(value, phase, path, errors) {
  const errorCount = errors.length;
  if (!isRecord(value)) {
    errors.push(`${path}.attribution must be an object`);
    return null;
  }
  exactKeys(value, ATTRIBUTION_KEYS, `${path}.attribution`, errors);
  for (const key of ATTRIBUTION_KEYS) {
    if (
      typeof value[key] !== "string"
      || !value[key].trim()
      || value[key].length > ATTRIBUTION_STRING_MAX_LENGTH
    ) {
      errors.push(
        `${path}.attribution.${key} must be a non-empty string at most `
          + `${ATTRIBUTION_STRING_MAX_LENGTH} characters`,
      );
    }
  }
  if (errors.length !== errorCount) return null;

  const roles = Object.hasOwn(CANONICAL_SPECIALISTS, value.member)
    ? CANONICAL_SPECIALISTS[value.member]
    : null;
  const specialist = roles !== null && Object.hasOwn(roles, value.role)
    ? roles[value.role]
    : null;
  if (specialist === null) {
    errors.push(`${path}.attribution is not a canonical Deep Review specialist`);
    return null;
  }
  if (phase !== specialist.phase) {
    errors.push(
      `${path}.phase must be ${JSON.stringify(specialist.phase)} for `
        + `${JSON.stringify(value.member)}`,
    );
    return null;
  }
  return {
    ...value,
    category: specialist.category,
    bucket: value.member,
  };
}

function validateUsageSnapshot(snapshot) {
  const errors = [];
  if (!isRecord(snapshot)) fail("usage snapshot must be an object");
  exactKeys(snapshot, TOP_LEVEL_KEYS, "usage", errors);
  safeInteger(snapshot.usedTokens, "usage.usedTokens", errors);
  safeInteger(snapshot.callCount, "usage.callCount", errors);
  if (!CREDIT_STATUSES.has(snapshot.creditStatus)) {
    errors.push("usage.creditStatus is invalid");
  }
  if (!Array.isArray(snapshot.calls)) {
    errors.push("usage.calls must be an array");
  }
  const calls = Array.isArray(snapshot.calls) ? snapshot.calls : [];
  if (Number.isSafeInteger(snapshot.callCount) && snapshot.callCount !== calls.length) {
    errors.push("usage.callCount must equal usage.calls.length");
  }

  const callIds = new Set();
  const attributionIdentities = new Set();
  let tokenTotal = 0n;
  let nanoTotal = 0n;
  let sawOverflow = false;
  let sawUnreported = false;
  const normalized = [];

  calls.forEach((call, index) => {
    const path = `usage.calls[${index}]`;
    if (!isRecord(call)) {
      errors.push(`${path} must be an object`);
      return;
    }
    exactKeys(call, CALL_KEYS, path, errors);
    const validCallId = nonEmptyString(call.callId, `${path}.callId`, errors);
    nonEmptyString(call.label, `${path}.label`, errors);
    const validPhase = nonEmptyString(call.phase, `${path}.phase`, errors);
    if (validCallId) {
      if (callIds.has(call.callId)) errors.push(`${path}.callId is duplicated`);
      callIds.add(call.callId);
    }
    if (call.model !== null && (typeof call.model !== "string" || !call.model.length)) {
      errors.push(`${path}.model must be null or a non-empty string`);
    }
    const tokensValid = [
      safeInteger(call.tokensIn, `${path}.tokensIn`, errors),
      safeInteger(call.tokensOut, `${path}.tokensOut`, errors),
      safeInteger(call.personaTokens, `${path}.personaTokens`, errors),
    ].every(Boolean);
    if (tokensValid) {
      tokenTotal += BigInt(call.tokensIn) + BigInt(call.tokensOut) + BigInt(call.personaTokens);
    }
    if (!CREDIT_STATUSES.has(call.creditStatus)) {
      errors.push(`${path}.creditStatus is invalid`);
    } else if (call.creditStatus === "overflow") {
      sawOverflow = true;
      if (call.nanoAiu !== null) errors.push(`${path}.nanoAiu must be null for overflow`);
    } else {
      if (safeInteger(call.nanoAiu, `${path}.nanoAiu`, errors)) {
        nanoTotal += BigInt(call.nanoAiu);
      }
      if (call.creditStatus === "unreported") {
        sawUnreported = true;
        if (call.nanoAiu !== 0) errors.push(`${path}.nanoAiu must be zero when unreported`);
      }
    }
    if (typeof call.failed !== "boolean") errors.push(`${path}.failed must be boolean`);
    const attribution = validPhase
      ? canonicalAttribution(call.attribution, call.phase, path, errors)
      : null;
    if (attribution !== null) {
      const identity = JSON.stringify([
        attribution.member,
        attribution.role,
        attribution.instance,
      ]);
      if (attributionIdentities.has(identity)) {
        errors.push(`${path}.attribution identity is duplicated`);
      }
      attributionIdentities.add(identity);
    }
    normalized.push({ ...call, attribution });
  });

  if (tokenTotal > BigInt(Number.MAX_SAFE_INTEGER)) {
    errors.push("usage token reconciliation exceeds Number.MAX_SAFE_INTEGER");
  } else if (Number(snapshot.usedTokens) !== Number(tokenTotal)) {
    errors.push("usage.usedTokens does not reconcile to call token totals");
  }

  const expectedStatus = creditStatusFor(
    normalized.length,
    sawOverflow,
    sawUnreported,
  );
  if (snapshot.creditStatus !== expectedStatus) {
    errors.push(`usage.creditStatus must be ${expectedStatus}`);
  }
  if (snapshot.creditStatus === "overflow") {
    if (snapshot.usedNanoAiu !== null) errors.push("usage.usedNanoAiu must be null for overflow");
    if (snapshot.usedCredits !== null) errors.push("usage.usedCredits must be null for overflow");
  } else {
    if (!safeInteger(snapshot.usedNanoAiu, "usage.usedNanoAiu", errors)) {
      // The helper records the useful error.
    } else if (nanoTotal > BigInt(Number.MAX_SAFE_INTEGER)) {
      errors.push("usage credit reconciliation exceeds Number.MAX_SAFE_INTEGER");
    } else if (snapshot.usedNanoAiu !== Number(nanoTotal)) {
      errors.push("usage.usedNanoAiu does not reconcile to call credit totals");
    }
    if (
      typeof snapshot.usedCredits !== "number"
      || !Number.isFinite(snapshot.usedCredits)
      || snapshot.usedCredits !== snapshot.usedNanoAiu / 1_000_000_000
    ) {
      errors.push("usage.usedCredits must equal usage.usedNanoAiu / 1_000_000_000");
    }
  }
  if (errors.length) fail("usage snapshot is invalid", errors);
  return {
    ...snapshot,
    calls: normalized.sort(compareCalls),
  };
}

function formatInteger(value) {
  return String(value).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function roundHalfEvenRatio(numerator, denominator) {
  const quotient = numerator / denominator;
  const remainder = numerator % denominator;
  const doubled = remainder * 2n;
  if (doubled < denominator) return quotient;
  if (doubled > denominator) return quotient + 1n;
  return quotient % 2n === 0n ? quotient : quotient + 1n;
}

function formatAiu(nanoAiu) {
  const hundredths = roundHalfEvenRatio(BigInt(nanoAiu), 10_000_000n);
  const whole = hundredths / 100n;
  const fraction = String(hundredths % 100n).padStart(2, "0");
  return `${formatInteger(whole)}.${fraction}`;
}

function formatPercent(nanoAiu, totalNanoAiu) {
  if (totalNanoAiu === 0) return "0.0%";
  const tenths = roundHalfEvenRatio(BigInt(nanoAiu) * 1000n, BigInt(totalNanoAiu));
  return `${tenths / 10n}.${tenths % 10n}%`;
}

function codeSpan(value) {
  const text = String(value).replace(
    /[\u0000-\u001f\u007f]/g,
    (character) => `\\u${character.codePointAt(0).toString(16).padStart(4, "0")}`,
  );
  const runs = text.match(/`+/g) ?? [];
  const fence = "`".repeat(Math.max(1, ...runs.map((run) => run.length + 1)));
  const padding = text.startsWith("`") || text.endsWith("`") ? " " : "";
  return `${fence}${padding}${text}${padding}${fence}`;
}

function escapeInline(value) {
  return String(value)
    .replace(/\s+/g, " ")
    .trim()
    .replace(/[\\*_[\]<>|]/g, "\\$&")
    .replaceAll("`", "\\`");
}

function escapeTableCell(value) {
  return escapeInline(value);
}

function modelsUsed(calls) {
  const counts = new Map();
  for (const call of calls) {
    const model = call.model ?? "?";
    counts.set(model, (counts.get(model) ?? 0) + 1);
  }
  return [...counts]
    .sort((left, right) => right[1] - left[1] || compareCodePointStrings(left[0], right[0]))
    .map(([model]) => model)
    .join("+") || "?";
}

function aggregate(calls, emptyStatus = UNREPORTED_CREDIT_STATUS) {
  const sawOverflow = calls.some((call) => call.creditStatus === "overflow");
  const sawUnreported = calls.some(
    (call) => call.creditStatus === UNREPORTED_CREDIT_STATUS,
  );
  return {
    calls: calls.length,
    failed: calls.filter((call) => call.failed).length,
    tokens: calls.reduce(
      (sum, call) => sum + call.tokensIn + call.tokensOut + call.personaTokens,
      0,
    ),
    nanoAiu: calls.reduce(
      (sum, call) => sum + (call.creditStatus === "reported" ? call.nanoAiu : 0),
      0,
    ),
    creditStatus: creditStatusFor(
      calls.length,
      sawOverflow,
      sawUnreported,
      emptyStatus,
    ),
  };
}

function groupByBucket(calls, category) {
  const grouped = new Map();
  for (const call of calls.filter((item) => item.attribution.category === category)) {
    const key = call.attribution.bucket;
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(call);
  }
  return [...grouped].sort((left, right) => compareCodePointStrings(left[0], right[0]));
}

function creditCell(stats) {
  if (stats.creditStatus === "overflow") return "overflow";
  if (stats.creditStatus === "unreported") return "unavailable";
  return formatAiu(stats.nanoAiu);
}

function percentCell(stats, usage) {
  if (usage.creditStatus !== "reported") return "\u2014";
  return formatPercent(stats.nanoAiu, usage.usedNanoAiu);
}

function knownEmptyCreditStatus() {
  return "reported";
}

function renderCategoryTable(lines, usage, category, heading, bucketHeading) {
  const emptyStatus = knownEmptyCreditStatus();
  lines.push(`## ${heading}\n`);
  lines.push(
    `| ${bucketHeading} | models used | roles | failed | OWS calls | tokens | AIU | % |`,
    "|---|---|---:|---:|---:|---:|---:|---:|",
  );
  const groups = groupByBucket(usage.calls, category);
  for (const [bucket, calls] of groups) {
    const stats = aggregate(calls, emptyStatus);
    const roles = new Set(calls.map((call) => call.attribution.role)).size;
    lines.push(
      `| ${escapeTableCell(bucket)} | ${escapeTableCell(modelsUsed(calls))} | ${roles} | ${stats.failed} | `
      + `${stats.calls} | ${formatInteger(stats.tokens)} | ${creditCell(stats)} | `
      + `${percentCell(stats, usage)} |`,
    );
  }
  const subtotalCalls = usage.calls.filter((call) => call.attribution.category === category);
  const subtotal = aggregate(subtotalCalls, emptyStatus);
  lines.push(
    `| **subtotal** | | | **${subtotal.failed}** | **${subtotal.calls}** | `
    + `**${formatInteger(subtotal.tokens)}** | **${creditCell(subtotal)}** | `
    + `**${percentCell(subtotal, usage)}** |\n`,
  );
}

function validateContext(context) {
  if (!isRecord(context)) fail("cost report context must be an object");
  const allowed = new Set(["usage", "runIdentity", "generatedAt", "target"]);
  const errors = [];
  exactKeys(context, allowed, "context", errors);
  nonEmptyString(context.runIdentity, "context.runIdentity", errors);
  if (
    typeof context.generatedAt !== "string"
    || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(context.generatedAt)
    || Number.isNaN(Date.parse(context.generatedAt))
    || context.generatedAt.startsWith("0000-")
    || new Date(Date.parse(context.generatedAt))
      .toISOString()
      .replace(".000Z", "Z") !== context.generatedAt
  ) {
    errors.push("context.generatedAt must be a canonical UTC second timestamp");
  }
  if (!isRecord(context.target)) {
    errors.push("context.target must be an object");
  } else {
    const targetKeys = new Set(["changedFiles", "prTitle"]);
    exactKeys(context.target, targetKeys, "context.target", errors);
    safeInteger(context.target.changedFiles, "context.target.changedFiles", errors);
    if (context.target.prTitle !== null && typeof context.target.prTitle !== "string") {
      errors.push("context.target.prTitle must be null or a string");
    }
  }
  if (errors.length) fail("cost report context is invalid", errors);
}

function renderCostReport(context) {
  validateContext(context);
  const generated = context.generatedAt.replace("T", " ").replace(/:\d{2}Z$/, " UTC");
  const targetBits = [`${formatInteger(context.target.changedFiles)} changed file(s)`];
  if (context.target.prTitle && context.target.prTitle.trim()) {
    targetBits.push(`PR: ${escapeInline(context.target.prTitle)}`);
  }
  if (context.usage === null) {
    return [
      "# Cost \u2014 Deep Code Review\n",
      `- Run: ${codeSpan(context.runIdentity)}`,
      `- Generated: ${generated}`,
      `- Target: ${targetBits.join(" \u00b7 ")}`,
      "",
      "## Usage unavailable\n",
      "This OWS host did not inject a settled usage ledger. Token, credit, model, "
        + "and model-call totals are unavailable rather than inferred.",
    ].join("\n");
  }
  const usage = validateUsageSnapshot(context.usage);
  const inputTokens = usage.calls.reduce((sum, call) => sum + call.tokensIn, 0);
  const outputTokens = usage.calls.reduce((sum, call) => sum + call.tokensOut, 0);
  const personaTokens = usage.calls.reduce((sum, call) => sum + call.personaTokens, 0);
  const totalStats = aggregate(usage.calls, usage.creditStatus);

  const lines = [
    "# Cost \u2014 Deep Code Review\n",
    `- Run: ${codeSpan(context.runIdentity)}`,
    `- Generated: ${generated}`,
    `- Target: ${targetBits.join(" \u00b7 ")}`,
    "- Note: usage is the immutable settled GAW ledger projection. Cache, reasoning, "
      + "internal model-call counts, and wall-clock timing are not exposed to OWS and "
      + "are reported as unavailable.\n",
    "## Totals (everything)\n",
    "| metric | value |",
    "|---|---:|",
    `| Input prompts | ${formatInteger(inputTokens)} |`,
    `| Persona instructions | ${formatInteger(personaTokens)} |`,
    "| Cache read | \u2014 |",
    "| Cache write | \u2014 |",
    "| Reasoning | \u2014 |",
    `| Output | ${formatInteger(outputTokens)} |`,
    `| **Total tokens** | **${formatInteger(usage.usedTokens)}** |`,
    `| **Total AIU** | **${creditCell(totalStats)}** |`,
    `| Credit provenance | ${usage.creditStatus} |`,
    `\n${formatInteger(usage.callCount)} settled OWS call`
      + `${usage.callCount === 1 ? "" : "s"}.\n`,
    "## Timing \u2014 wall-clock (elapsed)\n",
    "| phase | wall-clock |",
    "|---|---:|",
    "| Whole run | \u2014 |",
    "| Reviewer phase (parallel wave) | \u2014 |",
    "| Verification phase | \u2014 |",
    "\nTiming is unavailable in the OWS usage projection; the separate governed run "
      + "receipt records authoritative elapsed time.\n",
  ];

  renderCategoryTable(lines, usage, "reviewer", "Reviewers \u2014 cost per review", "review");

  lines.push(
    "## Per-call breakdown\n",
    "| phase | bucket | role | instance | model | failed | tokens | credit | AIU |",
    "|---|---|---|---|---|---:|---:|---|---:|",
  );
  for (const call of usage.calls) {
    const tokens = call.tokensIn + call.tokensOut + call.personaTokens;
    const aiu = call.creditStatus === "reported" ? formatAiu(call.nanoAiu) : "\u2014";
    lines.push(
      `| ${escapeTableCell(call.phase)} | ${escapeTableCell(call.attribution.bucket)} | `
      + `${escapeTableCell(call.attribution.role)} | `
      + `${escapeTableCell(call.attribution.instance)} | ${escapeTableCell(call.model ?? "?")} | `
      + `${call.failed ? 1 : 0} | `
      + `${formatInteger(tokens)} | ${call.creditStatus} | ${aiu} |`,
    );
  }
  lines.push(
    "\n_One row per settled OWS `agent()` call. This is not the backend's internal "
      + "model-API call count._\n",
  );

  renderCategoryTable(
    lines,
    usage,
    "verification",
    "Consensus / verification pipeline",
    "stage",
  );
  renderCategoryTable(lines, usage, "orchestrator", "Orchestrator", "stage");
  lines.push("## Where the spend went\n");
  for (const [category, label] of [
    ["reviewer", "Reviewers"],
    ["verification", "Consensus / verification"],
    ["orchestrator", "Orchestrator"],
  ]) {
    const calls = usage.calls.filter((call) => call.attribution.category === category);
    const stats = aggregate(calls, knownEmptyCreditStatus());
    lines.push(
      `- ${label}: ${creditCell(stats)} AIU (${percentCell(stats, usage)})`,
    );
  }
  return `${lines.join("\n")}\n`;
}
return Object.freeze({ CostContractError, validateUsageSnapshot, renderCostReport });
})();

const Graph = (() => {
/**
 * Native Deep Code Review orchestration.
 *
 * Agents discover, merge, advocate, and judge. JavaScript owns every graph
 * edge, identity, schema gate, preservation check, and final projection.
 */

const TOOLKIT_MEMBER = "claude-code--pr-review-toolkit";
const AREA_MEMBER = "dynamic-review-areas";
const TOOLKIT_ROLES = Object.freeze([
  "code-reviewer",
  "pr-test-analyzer",
  "comment-analyzer",
  "silent-failure-hunter",
  "type-design-analyzer",
  "code-simplifier",
]);
const MANDATORY_TOOLKIT_ROLES = new Set([
  "code-reviewer",
  "code-simplifier",
]);
const TOOLKIT_DISPLAY_LABELS = Object.freeze({
  "code-reviewer": "Code reviewer",
  "pr-test-analyzer": "PR test analyzer",
  "comment-analyzer": "Comment analyzer",
  "silent-failure-hunter": "Silent failure hunter",
  "type-design-analyzer": "Type design analyzer",
  "code-simplifier": "Code simplifier",
});
const FINDING_KEYS = Object.freeze([
  "file",
  "line_start",
  "line_end",
  "category",
  "severity",
  "confidence",
  "title",
  "claim",
  "failure_scenario",
  "evidence",
]);
const SEVERITIES = new Set(["critical", "moderate", "nit"]);
const FINDING_TEXT_KEYS = Object.freeze([
  "category",
  "title",
  "claim",
  "failure_scenario",
  "evidence",
]);
const MAX_FINDING_TEXT_BYTES = 64 * 1024;
const UTF8_ENCODER = new TextEncoder();
const NON_RETRYABLE_AGENT_FAILURE = /^(?:agent_limit_exceeded:|per-subagent budget:|worktree isolation unavailable:|model not allowed by policy:|run already finalized$|invalid or regressive settle watermark from parent$|ledger coordinate refused \(fail-closed\):|agent (?:timeout|Git evidence|resolution|synthesis|budget request|access request) refused \(fail-closed\):|governance denied dispatch \(fail-closed\):)/i;

function attemptInstance(base, attempt) {
  return attempt === 0 ? base : `${base}-retry-${attempt}`;
}

function areaInstanceBase(ordinal) {
  return `area-${ordinal + 1}`;
}

function closedObject(required, properties) {
  return { type: "object", additionalProperties: false, required, properties };
}

const STRING = Object.freeze({ type: "string" });
const INTEGER = Object.freeze({ type: "integer" });
const POSITIVE_INTEGER = Object.freeze({ type: "integer", minimum: 1 });
const NUMBER = Object.freeze({ type: "number" });
const FINDING_TEXT = Object.freeze({ type: "string", maxLength: MAX_FINDING_TEXT_BYTES });
const FINDING_SCHEMA = closedObject(FINDING_KEYS, {
  file: STRING,
  line_start: POSITIVE_INTEGER,
  line_end: POSITIVE_INTEGER,
  category: FINDING_TEXT,
  severity: { type: "string", enum: ["critical", "moderate", "nit"] },
  confidence: NUMBER,
  title: FINDING_TEXT,
  claim: FINDING_TEXT,
  failure_scenario: FINDING_TEXT,
  evidence: FINDING_TEXT,
});
const REVIEW_SCHEMA = closedObject(["agent", "findings"], {
  agent: STRING,
  findings: { type: "array", items: FINDING_SCHEMA },
});
const TOOLKIT_SELECTION_SCHEMA = closedObject(["decisions"], {
  decisions: {
    type: "array",
    items: closedObject(["role", "applicable", "reason"], {
      role: { type: "string", enum: TOOLKIT_ROLES },
      applicable: { type: "boolean" },
      reason: { type: "string", minLength: 1 },
    }),
  },
});
const AREAS_SCHEMA = closedObject(["pr", "areas"], {
  pr: STRING,
  areas: {
    type: "array",
    items: closedObject(["id", "name", "files", "scrutinize", "risk"], {
      id: STRING,
      name: STRING,
      files: { type: "array", items: STRING },
      scrutinize: STRING,
      risk: { type: "string", enum: ["high", "med", "low"] },
    }),
  },
});
const CANDIDATES_SCHEMA = closedObject(
  ["candidates", "n_findings", "n_candidates"],
  {
    candidates: { type: "array", items: { type: "object" } },
    n_findings: INTEGER,
    n_candidates: INTEGER,
  },
);
const BRIEFS_SCHEMA = closedObject(["unit_id", "advocate_id", "briefs"], {
  unit_id: STRING,
  advocate_id: { type: "string", enum: ["tp", "fp"] },
  briefs: { type: "array", items: { type: "object" } },
});
const JUDGMENTS_SCHEMA = closedObject(["unit_id", "judge_id", "verdicts"], {
  unit_id: STRING,
  judge_id: STRING,
  verdicts: { type: "array", items: { type: "object" } },
});

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function exactKeys(value, keys, path) {
  if (!isRecord(value)) throw new TypeError(`${path} must be an object`);
  const actual = Object.keys(value).sort();
  const expected = [...keys].sort();
  if (actual.length !== expected.length
      || actual.some((key, index) => key !== expected[index])) {
    throw new TypeError(`${path} must have exactly these keys: ${expected.join(", ")}`);
  }
}

function nonEmptyString(value, path) {
  if (typeof value !== "string" || !value.trim()) {
    throw new TypeError(`${path} must be a non-empty string`);
  }
}

function repositoryRelativePath(value, path) {
  nonEmptyString(value, path);
  if (value.includes("\\") || value.startsWith("/") || /^[A-Za-z]:\//.test(value)
      || value.split("/").some((segment) => !segment || segment === "." || segment === "..")) {
    throw new TypeError(`${path} must be a canonical repository-relative path`);
  }
}

function promptPayload(entries) {
  return Object.entries(entries)
    .map(([key, value]) => `${key}=${typeof value === "string" ? value : JSON.stringify(value)}`)
    .join("\n");
}

function reviewFiles(facts, plan) {
  return plan.windowFiles ?? facts.git.currentChangedFiles;
}

function validateFindingLocationAndText(value, path) {
  for (const key of ["line_start", "line_end"]) {
    if (!Number.isInteger(value[key]) || value[key] < 1) {
      throw new TypeError(`${path}.${key} must be a positive integer`);
    }
  }
  if (value.line_start > value.line_end) {
    throw new TypeError(`${path} has an inverted line range`);
  }
  let textBytes = 0;
  for (const key of FINDING_TEXT_KEYS) {
    if (typeof value[key] !== "string") throw new TypeError(`${path}.${key} must be a string`);
    textBytes += UTF8_ENCODER.encode(value[key]).length;
  }
  if (textBytes > MAX_FINDING_TEXT_BYTES) {
    throw new TypeError(
      `${path} text exceeds ${MAX_FINDING_TEXT_BYTES} UTF-8 bytes`,
    );
  }
}

function validateFinding(value, path) {
  exactKeys(value, FINDING_KEYS, path);
  repositoryRelativePath(value.file, `${path}.file`);
  validateFindingLocationAndText(value, path);
  if (!SEVERITIES.has(value.severity)) throw new TypeError(`${path}.severity is invalid`);
  if (typeof value.confidence !== "number" || !Number.isFinite(value.confidence)
      || value.confidence < 0 || value.confidence > 1) {
    throw new TypeError(`${path}.confidence must be between zero and one`);
  }
}

function validateReview(document, expectedAgent, path) {
  exactKeys(document, ["agent", "findings"], path);
  if (document.agent !== expectedAgent) {
    throw new TypeError(`${path}.agent must equal ${expectedAgent}`);
  }
  if (!Array.isArray(document.findings)) throw new TypeError(`${path}.findings must be an array`);
  document.findings.forEach((finding, index) =>
    validateFinding(finding, `${path}.findings[${index}]`));
  return document;
}

function validateToolkitSelection(document) {
  exactKeys(document, ["decisions"], "toolkit applicability");
  if (!Array.isArray(document.decisions)) {
    throw new TypeError("toolkit applicability decisions must be an array");
  }
  if (document.decisions.length !== TOOLKIT_ROLES.length) {
    throw new TypeError("toolkit applicability must decide every toolkit role exactly once");
  }
  const decisions = new Map();
  document.decisions.forEach((decision, index) => {
    const path = `toolkit applicability.decisions[${index}]`;
    exactKeys(decision, ["role", "applicable", "reason"], path);
    if (!TOOLKIT_ROLES.includes(decision.role)) throw new TypeError(`${path}.role is invalid`);
    if (decisions.has(decision.role)) throw new TypeError(`${path}.role is duplicated`);
    if (typeof decision.applicable !== "boolean") {
      throw new TypeError(`${path}.applicable must be boolean`);
    }
    nonEmptyString(decision.reason, `${path}.reason`);
    decisions.set(decision.role, decision.applicable);
  });
  for (const role of TOOLKIT_ROLES) {
    if (!decisions.has(role)) throw new TypeError(`toolkit applicability omitted ${role}`);
  }
  return TOOLKIT_ROLES.filter(
    (role) => MANDATORY_TOOLKIT_ROLES.has(role) || decisions.get(role),
  );
}

function validateAreas(document, changedFiles) {
  exactKeys(document, ["pr", "areas"], "area planner output");
  if (!Array.isArray(document.areas) || document.areas.length < 3 || document.areas.length > 10) {
    throw new TypeError("area planner must return between three and ten areas");
  }
  const ids = new Set();
  const coverage = new Map(changedFiles.map((path) => [path, 0]));
  document.areas.forEach((area, index) => {
    const path = `area planner output.areas[${index}]`;
    exactKeys(area, ["id", "name", "files", "scrutinize", "risk"], path);
    for (const key of ["id", "name", "scrutinize"]) nonEmptyString(area[key], `${path}.${key}`);
    if (ids.has(area.id)) throw new TypeError(`${path}.id is duplicated`);
    ids.add(area.id);
    if (!["high", "med", "low"].includes(area.risk)) throw new TypeError(`${path}.risk is invalid`);
    if (!Array.isArray(area.files) || !area.files.length) {
      throw new TypeError(`${path}.files must be a non-empty array`);
    }
    const areaFiles = new Set();
    for (const file of area.files) {
      if (!coverage.has(file)) throw new TypeError(`${path}.files contains unchanged file ${file}`);
      if (areaFiles.has(file)) throw new TypeError(`${path}.files duplicates ${file}`);
      areaFiles.add(file);
      coverage.set(file, coverage.get(file) + 1);
    }
  });
  const uncovered = [...coverage].filter(([, count]) => count === 0);
  if (uncovered.length) {
    throw new TypeError(
      `area planner must cover every changed file: ${uncovered.map(([file]) => file).join(", ")}`,
    );
  }
  return document.areas;
}

function validateBriefs(document, unit, advocateId) {
  exactKeys(document, ["unit_id", "advocate_id", "briefs"], `${advocateId} briefs`);
  if (document.unit_id !== unit.unit_id || document.advocate_id !== advocateId) {
    throw new TypeError(`${advocateId} briefs identity does not match unit`);
  }
  if (!Array.isArray(document.briefs) || document.briefs.length !== unit.cand_ids.length) {
    throw new TypeError(`${advocateId} briefs must cover every candidate exactly once`);
  }
  const ids = document.briefs.map((brief) => brief?.cand_id);
  if (ids.some((id, index) => id !== unit.cand_ids[index])) {
    throw new TypeError(`${advocateId} briefs candidate order or identity is invalid`);
  }
  const expectedKeys = advocateId === "tp"
    ? [
      "cand_id", "side", "thesis", "argument", "key_code_facts", "rebuttal",
      "honest_concession", "claimed_severity",
    ]
    : [
      "cand_id", "side", "thesis", "argument", "key_code_facts", "rebuttal",
      "honest_concession", "fp_basis",
    ];
  document.briefs.forEach((brief, index) => {
    const path = `${advocateId} briefs.briefs[${index}]`;
    exactKeys(brief, expectedKeys, path);
    const expectedSide = advocateId === "tp" ? "true_positive" : "false_positive";
    if (brief.side !== expectedSide) throw new TypeError(`${path}.side is invalid`);
    for (const key of ["thesis", "argument", "rebuttal", "honest_concession"]) {
      nonEmptyString(brief[key], `${path}.${key}`);
    }
    if (!Array.isArray(brief.key_code_facts)
        || brief.key_code_facts.some((fact) => typeof fact !== "string" || !fact.trim())) {
      throw new TypeError(`${path}.key_code_facts must contain non-empty strings`);
    }
    if (advocateId === "tp" && !SEVERITIES.has(brief.claimed_severity)) {
      throw new TypeError(`${path}.claimed_severity is invalid`);
    }
    if (advocateId === "fp" && ![
      "none",
      "root-cause-out-of-window",
      "unreachable",
      "misread",
      "claim-false",
      "not-exploitable",
      "already-guaranteed",
      "noise",
    ].includes(brief.fp_basis)) {
      throw new TypeError(`${path}.fp_basis is invalid`);
    }
  });
  return document;
}

function validateJudgmentDocument(document, unit) {
  exactKeys(document, ["unit_id", "judge_id", "verdicts"], `judgment ${unit.unit_id}`);
  if (document.unit_id !== unit.unit_id || document.judge_id !== "j0") {
    throw new TypeError(`judgment ${unit.unit_id} identity mismatch`);
  }
  if (!Array.isArray(document.verdicts) || document.verdicts.length !== unit.cand_ids.length) {
    throw new TypeError(`judgment ${unit.unit_id} must cover every candidate exactly once`);
  }
  document.verdicts.forEach((verdict, index) => {
    const path = `judgment ${unit.unit_id}.verdicts[${index}]`;
    exactKeys(verdict, [
      "cand_id",
      "verdict",
      "which_advocate_won",
      "decisive_fact",
      "independent_code_check",
      "reasoning",
    ], path);
    if (verdict.cand_id !== unit.cand_ids[index]) {
      throw new TypeError(`${path}.cand_id is out of order`);
    }
    if (!["VALID_FINDING", "INVALID_FINDING"].includes(verdict.verdict)) {
      throw new TypeError(`${path}.verdict is invalid`);
    }
    if (!["tp", "fp"].includes(verdict.which_advocate_won)) {
      throw new TypeError(`${path}.which_advocate_won is invalid`);
    }
    for (const key of ["decisive_fact", "independent_code_check", "reasoning"]) {
      nonEmptyString(verdict[key], `${path}.${key}`);
    }
  });
  return document;
}

function requireParallel(results, names, stage) {
  results.forEach((result, index) => {
    if (result === null) throw new Error(`${stage} agent failed: ${names[index]}`);
  });
  return results;
}

async function settleRetryAttempt(thunk, attempt) {
  try {
    const value = await thunk(attempt);
    if (value === null) {
      const failure = new Error("agent dispatch returned null");
      failure.__nonRetryable = true;
      throw failure;
    }
    return { ok: true, retryable: false, value };
  } catch (error) {
    if (isRunTerminalAgentFailure(error)) throw error;
    return {
      ok: false,
      retryable: !isNonRetryableAgentFailure(error),
      value: null,
    };
  }
}

async function parallelWithOneRetry(thunks, names) {
  const initial = await parallel(thunks.map((thunk) => () =>
    settleRetryAttempt(thunk, 0)));
  const retryIndexes = initial.flatMap((result, index) =>
    !result.ok && result.retryable ? [index] : []);
  const retries = retryIndexes.length
    ? await parallel(retryIndexes.map((index) => () =>
      settleRetryAttempt(thunks[index], 1)))
    : [];
  const results = initial.map((result) => result.value);
  retryIndexes.forEach((resultIndex, retryIndex) => {
    if (retries[retryIndex].ok) results[resultIndex] = retries[retryIndex].value;
  });
  return {
    results,
    failed: initial.map((_result, index) => index)
      .filter((index) => results[index] === null)
      .map((index) => names[index]),
  };
}

function boundedFailureMessage(error) {
  const raw = String(error?.message ?? error ?? "agent call failed");
  const normalized = raw
    .replace(/[\u0000-\u001f\u007f]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  return (normalized || "agent call failed").slice(0, 512);
}

function isRunTerminalAgentFailure(error) {
  return error?.__budget === true || error?.__gawFatal === true;
}

function isNonRetryableAgentFailure(error) {
  return isRunTerminalAgentFailure(error)
    || error?.__governance === true
    || error?.__nonRetryable === true
    || NON_RETRYABLE_AGENT_FAILURE.test(boundedFailureMessage(error));
}

function discoveryFailure(outcome, error) {
  const failure = new Error(boundedFailureMessage(error));
  failure.discoveryOutcome = outcome;
  failure.__nonRetryable = isNonRetryableAgentFailure(error);
  return failure;
}

async function validatedDiscoveryCall(agentCall, validate) {
  let document;
  try {
    document = await agentCall();
    if (document === null) {
      const failure = new Error("agent dispatch returned null");
      failure.__nonRetryable = true;
      throw failure;
    }
  } catch (error) {
    if (isRunTerminalAgentFailure(error)) throw error;
    throw discoveryFailure("agent_call_failed", error);
  }
  try {
    return validate(document);
  } catch (error) {
    throw discoveryFailure("response_validation_failed", error);
  }
}

async function settleDiscoveryAttempt(thunk, descriptor, attempt) {
  try {
    return {
      ok: true,
      value: await thunk(attempt),
      record: {
        member: descriptor.member,
        role: descriptor.role,
        instance: descriptor.instance,
        attempt,
        outcome: "accepted",
        failureMessage: null,
      },
    };
  } catch (error) {
    if (isRunTerminalAgentFailure(error)) throw error;
    return {
      ok: false,
      retryable: !isNonRetryableAgentFailure(error),
      value: null,
      record: {
        member: descriptor.member,
        role: descriptor.role,
        instance: descriptor.instance,
        attempt,
        outcome: error?.discoveryOutcome ?? "agent_call_failed",
        failureMessage: boundedFailureMessage(error),
      },
    };
  }
}

async function discoveryWithOneRetry(thunks, descriptors) {
  const initial = await parallel(thunks.map((thunk, index) => () =>
    settleDiscoveryAttempt(thunk, descriptors[index], 0)));
  const failedIndexes = initial.flatMap((result, index) => result.ok ? [] : [index]);
  const retryIndexes = initial.flatMap((result, index) =>
    !result.ok && result.retryable ? [index] : []);
  const retries = retryIndexes.length
    ? await parallel(retryIndexes.map((index) => () =>
      settleDiscoveryAttempt(thunks[index], descriptors[index], 1)))
    : [];
  const results = initial.map((result) => result.value);
  retryIndexes.forEach((resultIndex, retryIndex) => {
    if (retries[retryIndex].ok) results[resultIndex] = retries[retryIndex].value;
  });
  const attempts = [
    ...initial.map((result) => result.record),
    ...retries.map((result) => result.record),
  ];
  return {
    results,
    attempts,
    failed: failedIndexes
      .filter((index) => results[index] === null)
      .map((index) => ({
        name: descriptors[index].name,
        attempts: attempts.filter((record) =>
          record.member === descriptors[index].member
          && record.role === descriptors[index].role
          && record.instance === descriptors[index].instance),
      })),
  };
}

function discoveryFailureSummary(failed) {
  return failed.map((failure) => {
    const attempts = failure.attempts.map((attempt) =>
      `attempt ${attempt.attempt} ${attempt.outcome}: ${attempt.failureMessage}`).join("; ");
    return `${failure.name} [${attempts}]`;
  }).join(", ");
}

function reviewCall(facts, plan, role, attempt = 0) {
  return validatedDiscoveryCall(
    () => agent(promptPayload({
      WORKTREE: ".",
      BASE: plan.baseT,
      HEAD: plan.curHead,
      PR_SUMMARY: `${plan.title}\n\n${facts.pr.body}`,
      OWS_RESPONSE: "Return the same exact JSON object as the structured response.",
    }), {
      agentType: `code-review--claude-code--pr-review-toolkit--${role}`,
      label: TOOLKIT_DISPLAY_LABELS[role],
      phase: "Run Reviewers",
      attribution: {
        member: TOOLKIT_MEMBER,
        role,
        instance: attemptInstance("main", attempt),
      },
      isolation: "worktree",
      schema: REVIEW_SCHEMA,
    }),
    (document) => validateReview(document, role, `review ${role}`),
  );
}

function selectToolkitRolesCall(facts, plan, attempt = 0) {
  return validatedDiscoveryCall(
    () => agent(promptPayload({
      WORKTREE: ".",
      BASE: plan.baseT,
      HEAD: plan.curHead,
      PR_SUMMARY: `${plan.title}\n\n${facts.pr.body}`,
      OWS_RESPONSE: "Return only the required toolkit applicability object.",
    }), {
      agentType: "code-review--claude-code--pr-review-toolkit--applicability",
      label: "Toolkit planner",
      phase: "Run Reviewers",
      attribution: {
        member: TOOLKIT_MEMBER,
        role: "applicability",
        instance: attemptInstance("main", attempt),
      },
      isolation: "worktree",
      schema: TOOLKIT_SELECTION_SCHEMA,
    }),
    validateToolkitSelection,
  );
}

async function selectToolkitRoles(facts, plan) {
  const run = await discoveryWithOneRetry([
    (attempt) => selectToolkitRolesCall(facts, plan, attempt),
  ], [{
    name: "applicability",
    member: TOOLKIT_MEMBER,
    role: "applicability",
    instance: "main",
  }]);
  if (run.failed.length) {
    throw new Error(
      `toolkit applicability agent failed after one retry: ${discoveryFailureSummary(run.failed)}`,
    );
  }
  return { roles: run.results[0], attempts: run.attempts };
}

async function toolkitDiscovery(facts, plan) {
  const selection = await selectToolkitRoles(facts, plan);
  const roles = selection.roles;
  const run = await discoveryWithOneRetry(
    roles.map((role) => (attempt) => reviewCall(facts, plan, role, attempt)),
    roles.map((role) => ({
      name: role,
      member: TOOLKIT_MEMBER,
      role,
      instance: "main",
    })),
  );
  if (run.failed.length) {
    throw new Error(
      `toolkit discovery agent failed after one retry: ${discoveryFailureSummary(run.failed)}`,
    );
  }
  return {
    member: TOOLKIT_MEMBER,
    text: JSON.stringify({ findings: Control.aggregateToolkitFindings(roles, run.results) }),
    attempts: [...selection.attempts, ...run.attempts],
    selectedToolkitRoles: roles,
  };
}

function areaPlannerCall(facts, plan, attempt = 0) {
  return validatedDiscoveryCall(
    () => agent(promptPayload({
      WORKTREE: ".",
      BASE: plan.baseT,
      HEAD: plan.curHead,
      CHANGED_FILES: reviewFiles(facts, plan),
      OWS_RESPONSE: [
        "Return the same exact JSON object as the structured response.",
        "Return 3-10 areas.",
        "Each files entry must exactly equal one CHANGED_FILES path with no annotation,",
        "every CHANGED_FILES path must occur in at least one area,",
        "and a path may repeat across areas for context but not within one area.",
      ].join(" "),
    }), {
      agentType: "code-review--dynamic-review-areas--area-planner",
      label: "Area planner",
      phase: "Run Reviewers",
      attribution: {
        member: AREA_MEMBER,
        role: "area-planner",
        instance: attemptInstance("main", attempt),
      },
      isolation: "worktree",
      schema: AREAS_SCHEMA,
    }),
    (document) => validateAreas(document, reviewFiles(facts, plan)),
  );
}

function areaReviewCall(facts, plan, area, ordinal, attempt = 0) {
  const instance = attemptInstance(areaInstanceBase(ordinal), attempt);
  return validatedDiscoveryCall(
    () => agent(promptPayload({
      WORKTREE: ".",
      BASE: plan.baseT,
      HEAD: plan.curHead,
      AREA_ID: area.id,
      AREA_NAME: area.name,
      SCRUTINIZE: area.scrutinize,
      FILES: area.files,
      OWS_RESPONSE: "Return the findings object as the structured response.",
    }), {
      agentType: "code-review--dynamic-review-areas--area-reviewer",
      label: "Area reviewer",
      phase: "Run Reviewers",
      attribution: {
        member: AREA_MEMBER,
        role: "area-reviewer",
        instance,
      },
      isolation: "worktree",
      schema: closedObject(["area_id", "findings"], {
        area_id: STRING,
        findings: { type: "array", items: FINDING_SCHEMA },
      }),
    }),
    (document) => {
      exactKeys(document, ["area_id", "findings"], `area review ${area.id}`);
      if (document.area_id !== area.id) {
        throw new TypeError(`area review ${area.id} identity mismatch`);
      }
      document.findings.forEach((finding, index) =>
        validateFinding(finding, `area review ${area.id}.findings[${index}]`));
      return document;
    },
  );
}

async function areaDiscovery(facts, plan) {
  const plannerRun = await discoveryWithOneRetry([
    (attempt) => areaPlannerCall(facts, plan, attempt),
  ], [{
    name: "area-planner",
    member: AREA_MEMBER,
    role: "area-planner",
    instance: "main",
  }]);
  if (plannerRun.failed.length) {
    throw new Error(
      `area planner agent failed after one retry: ${discoveryFailureSummary(plannerRun.failed)}`,
    );
  }
  const areas = plannerRun.results[0];
  const reviewRun = await discoveryWithOneRetry(
    areas.map((area, ordinal) => (attempt) =>
      areaReviewCall(facts, plan, area, ordinal, attempt)),
    areas.map((area, ordinal) => ({
      name: area.id,
      member: AREA_MEMBER,
      role: "area-reviewer",
      instance: areaInstanceBase(ordinal),
    })),
  );
  if (reviewRun.failed.length) {
    throw new Error(
      `area discovery agent failed after one retry: ${discoveryFailureSummary(reviewRun.failed)}`,
    );
  }
  return {
    member: AREA_MEMBER,
    text: JSON.stringify({ findings: Control.collateAreaFindings(reviewRun.results) }),
    attempts: [...plannerRun.attempts, ...reviewRun.attempts],
    plannedAreaIds: areas.map((area) => area.id),
  };
}

async function discovery(facts, plan) {
  const [toolkit, areas] = await Promise.all([
    toolkitDiscovery(facts, plan),
    areaDiscovery(facts, plan),
  ]);
  return {
    members: [
      { member: toolkit.member, text: toolkit.text },
      { member: areas.member, text: areas.text },
    ],
    health: {
      attempts: [...toolkit.attempts, ...areas.attempts],
      selectedToolkitRoles: toolkit.selectedToolkitRoles,
      plannedAreaIds: areas.plannedAreaIds,
    },
  };
}

async function mergeCandidates(facts, plan, pool) {
  let priorDocument = null;
  let validationErrors = [];
  const attemptDiagnostics = [];
  const attempts = [];
  const recordAttempt = (attempt, outcome, failureMessage) => {
    attempts.push({
      member: "code-review--dedup-merge",
      role: "merge",
      instance: "main",
      attempt,
      outcome,
      failureMessage,
    });
  };
  for (let attempt = 0; attempt < 2; attempt += 1) {
    const instance = attemptInstance("main", attempt);
    let document;
    try {
      document = await agent(promptPayload({
        POOL: pool,
        WORKTREE: ".",
        BASE: plan.baseT,
        HEAD: plan.curHead,
        CHECKER: "The OWS runs the authoritative JavaScript ledger gate after this call.",
        ...(priorDocument === null ? {} : {
          PRIOR_LEDGER: priorDocument,
          VALIDATION_ERRORS: validationErrors,
          REPAIR_INSTRUCTION: "Return a complete corrected ledger that fixes every validation error.",
        }),
        OWS_RESPONSE: "Return candidates.json as the structured response.",
      }), {
        agentType: "code-review--dedup-merge",
        label: "Findings merger",
        phase: "Merge Findings",
        attribution: {
          member: "code-review--dedup-merge",
          role: "merge",
          instance,
        },
        isolation: "worktree",
        schema: CANDIDATES_SCHEMA,
      });
    } catch (error) {
      if (isNonRetryableAgentFailure(error)) throw error;
      const failureMessage = boundedFailureMessage(error);
      recordAttempt(attempt, "agent_call_failed", failureMessage);
      attemptDiagnostics.push(
        `attempt ${attempt}: agent call failed: ${failureMessage}`,
      );
      continue;
    }
    try {
      Control.validateCandidateLedger(document, pool);
      document.candidates.forEach((candidate, index) =>
        validateFindingLocationAndText(candidate, `candidate ledger.candidates[${index}]`));
      recordAttempt(attempt, "accepted", null);
      return { candidateLedger: document, attempts };
    } catch (error) {
      priorDocument = document;
      if (error instanceof Control.ControlContractError) {
        validationErrors = error.details.map(String);
      } else if (error instanceof TypeError) {
        validationErrors = [boundedFailureMessage(error)];
      } else {
        throw error;
      }
      recordAttempt(
        attempt,
        "response_validation_failed",
        boundedFailureMessage(error),
      );
      attemptDiagnostics.push(
        `attempt ${attempt}: validation failed: ${validationErrors.join("; ")}`,
      );
    }
  }
  throw new TypeError(
    `candidate ledger remained invalid after one repair: ${attemptDiagnostics.join(" | ")}`,
  );
}

async function advocateCall(facts, plan, unit, side, attempt = 0) {
  const advocateId = side === "tp" ? "code-review--advocate--is-true-positive"
    : "code-review--advocate--is-false-positive";
  const role = side === "tp" ? "true-positive-advocate" : "false-positive-advocate";
  const advocateSide = side === "tp" ? "true_positive" : "false_positive";
  const instance = attemptInstance(`${unit.unit_id}-${side}`, attempt);
  const document = await agent(promptPayload({
    WORKTREE: ".",
    BASE: plan.baseT,
    HEAD: plan.curHead,
    UNIT_ID: unit.unit_id,
    CANDIDATE_IDS: unit.cand_ids,
    CANDIDATES: unit.candidates,
    ADVOCATE_ID: side,
    ADVOCATE_SIDE: advocateSide,
    OWS_RESPONSE: `Return only {"unit_id":"${unit.unit_id}","advocate_id":"${side}","briefs":[...]}; briefs must follow CANDIDATE_IDS exactly.`,
  }), {
    agentType: advocateId,
    label: side === "tp" ? "True-positive advocate" : "False-positive advocate",
    phase: "Judge Findings",
    attribution: { member: advocateId, role, instance },
    isolation: "worktree",
    schema: BRIEFS_SCHEMA,
  });
  return validateBriefs(document, unit, side);
}

async function judgeCall(facts, plan, unit, tp, fp, attempt = 0) {
  const instance = attemptInstance(`${unit.unit_id}-j0`, attempt);
  return agent(promptPayload({
    WORKTREE: ".",
    BASE: plan.baseT,
    HEAD: plan.curHead,
    UNIT_ID: unit.unit_id,
    JUDGE_ID: "j0",
    CANDIDATE_IDS: unit.cand_ids,
    CANDIDATES: unit.candidates,
    TP_BRIEFS: tp,
    FP_BRIEFS: fp,
    OWS_RESPONSE: `Return only {"unit_id":"${unit.unit_id}","judge_id":"j0","verdicts":[...]}; verdicts must follow CANDIDATE_IDS exactly.`,
  }), {
    agentType: "code-review--judge",
    label: "Judge",
    phase: "Judge Findings",
    attribution: {
      member: "code-review--judge",
      role: "judge",
      instance,
    },
    isolation: "worktree",
    schema: JUDGMENTS_SCHEMA,
  }).then((document) => validateJudgmentDocument(document, unit));
}

async function verifyCandidates(facts, plan, candidateDocument) {
  const unitsDocument = Control.groupVerificationUnits(candidateDocument);
  if (!unitsDocument.units.length) return {};
  phase("Judge Findings");
  const judgeResults = [];
  for (const unit of unitsDocument.units) {
    const advocateRun = await parallelWithOneRetry([
      (attempt) => advocateCall(facts, plan, unit, "tp", attempt),
      (attempt) => advocateCall(facts, plan, unit, "fp", attempt),
    ], [`${unit.unit_id}-tp`, `${unit.unit_id}-fp`]);
    if (advocateRun.failed.length) {
      judgeResults.push({ ok: false, stage: "advocate", workers: advocateRun.failed });
      continue;
    }
    const [tp, fp] = advocateRun.results;
    const judgeRun = await parallelWithOneRetry([
      (attempt) => judgeCall(facts, plan, unit, tp, fp, attempt),
    ], [`${unit.unit_id}-j0`]);
    if (judgeRun.failed.length) {
      judgeResults.push({ ok: false, stage: "judge", workers: judgeRun.failed });
      continue;
    }
    judgeResults.push({ ok: true, judgment: judgeRun.results[0] });
  }
  requireParallel(judgeResults, unitsDocument.units.map((unit) => unit.unit_id), "verification unit");
  for (const result of judgeResults) {
    if (!result.ok) {
      throw new Error(
        `${result.stage} agent failed after one retry: ${result.workers.join(", ")}`,
      );
    }
  }
  return Control.requireCompleteJudgments(
    unitsDocument,
    judgeResults.map((result) => result.judgment),
  );
}

async function runReviewGraph(facts, plan) {
  phase("Run Reviewers");
  const discovered = await discovery(facts, plan);
  phase("Merge Findings");
  const normalized = Normalize.normalizeFindingPool(discovered.members);
  const pool = Normalize.requireHealthyFindingPool(normalized);
  const merger = await mergeCandidates(facts, plan, pool);
  const candidates = merger.candidateLedger;
  const judgments = await verifyCandidates(facts, plan, candidates);
  const synthesis = Control.synthesizeReview(candidates, judgments);
  const normalizationAttempts = normalizationWarningAttempts(normalized.diagnostics);
  const health = buildReviewHealth({
    ...discovered.health,
    attempts: [
      ...discovered.health.attempts,
      ...merger.attempts,
      ...normalizationAttempts,
    ],
  }, pool, candidates);
  const warningSuffix = normalizationAttempts.length
    ? `; ${normalizationAttempts.length} reviewer normalization warning(s) retained in health`
    : "";
  return {
    status: "reviewed",
    reason: `${plan.mode} review completed with ${synthesis.summary.CONFIRMED} confirmed finding(s)${warningSuffix}`,
    candidates,
    judgments,
    synthesis,
    health,
  };
}

function normalizationWarningAttempts(diagnostics) {
  return diagnostics
    .filter((diagnostic) => diagnostic.status === "warning")
    .map((diagnostic) => ({
      member: diagnostic.member,
      role: "normalization",
      instance: diagnostic.member,
      attempt: 0,
      outcome: "response_validation_failed",
      failureMessage: `normalization parsed 0 findings from ${diagnostic.strategy} reviewer output`,
    }));
}

function buildReviewHealth(discoveryHealth, pool, candidates) {
  const representedPoolIndexes = new Set(
    candidates.candidates.flatMap((candidate) =>
      candidate.variants.map((variant) => variant.idx)),
  ).size;
  const memberFindingCounts = [TOOLKIT_MEMBER, AREA_MEMBER].map((member) => ({
    member,
    rawFindings: pool.filter((finding) => finding._member === member).length,
  }));
  return {
    discovery: {
      ...discoveryHealth,
      retryAttempted: discoveryHealth.attempts
        .filter((attempt) => attempt.attempt === 1).length,
      retryRecovered: discoveryHealth.attempts
        .filter((attempt) => attempt.attempt === 1 && attempt.outcome === "accepted").length,
    },
    findings: {
      members: memberFindingCounts,
      totalRawFindings: pool.length,
      candidates: candidates.n_candidates,
      representedPoolIndexes,
      candidateCoverageComplete: representedPoolIndexes === pool.length,
    },
  };
}
return Object.freeze({ validateFinding, validateBriefs, validateJudgmentDocument, mergeCandidates, runReviewGraph, normalizationWarningAttempts, buildReviewHealth });
})();

const DeepGraph = (() => {
  const ROSTER = Object.freeze(["code-review--advocate--is-false-positive","code-review--advocate--is-true-positive","code-review--claude-code--pr-review-toolkit--applicability","code-review--claude-code--pr-review-toolkit--code-reviewer","code-review--claude-code--pr-review-toolkit--code-simplifier","code-review--claude-code--pr-review-toolkit--comment-analyzer","code-review--claude-code--pr-review-toolkit--pr-test-analyzer","code-review--claude-code--pr-review-toolkit--silent-failure-hunter","code-review--claude-code--pr-review-toolkit--type-design-analyzer","code-review--dedup-merge","code-review--dynamic-review-areas--area-planner","code-review--dynamic-review-areas--area-reviewer","code-review--judge"]);

  function parsedArgs(value) {
    const parsed = typeof value === "string" ? JSON.parse(value) : value;
    if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new TypeError("ReviewFactsV2 input must be an object");
    }
    return parsed;
  }

  function emptyCandidates() {
    return { candidates: [], n_findings: 0, n_candidates: 0 };
  }

  function decisionReport(status, reason) {
    return `# Deep Code Review — decision

- Status: ${status}
- Reason: ${reason}
`;
  }

  function reviewObservation(facts, idempotencyMarker) {
    const reviews = facts.reviews
      .filter((review) => review.authorLogin === facts.execution.postingLogin)
      .sort((left, right) => left.id - right.id);
    const submitted = reviews.map((review) => review.submittedAt).filter(Boolean).sort();
    return {
      authorLogin: facts.execution.postingLogin,
      knownReviewIds: reviews.map((review) => review.id),
      maxSubmittedAt: submitted.length ? submitted.at(-1) : null,
      idempotencyMarker,
    };
  }

  function costSummary(snapshot) {
    if (snapshot === null) return {};
    const summary = { total_tokens: snapshot.usedTokens };
    if (snapshot.creditStatus === "reported") summary.total_aiu = snapshot.usedCredits;
    return summary;
  }

  function githubActionsRunId(runIdentity) {
  const match = /^run-([1-9][0-9]*)-[1-9][0-9]*$/.exec(runIdentity);
  return match === null ? "" : match[1];
}

  function buildAdvancePost(facts, plan, snapshot) {
    const review = Post.constructReviewPayload({
      owner: plan.owner,
      repo: plan.repo,
      number: plan.pr,
      event: "COMMENT",
      commitId: plan.curHead,
      confirmed: [],
      counts: { confirmed: 0, uncertain: 0, rejected: 0 },
      inputs: { head: plan.curHead, base: plan.newMergeBase },
      cost: costSummary(snapshot),
      roster: Post.candidateRoster([]),
      runSlug: facts.ownedResources.identity.runIdentity,
      anchorDiff: plan.anchorDiff,
      threeDotBase: plan.newMergeBase,
      postedAt: facts.execution.generatedAt,
      actions: {
        serverUrl: facts.request.serverUrl,
        repository: plan.repoSlug,
        runId: githubActionsRunId(facts.ownedResources.identity.runIdentity),
      },
    });
    const idempotencyMarker = Post.markerComment(review.marker);
    return {
      schemaVersion: 1,
      kind: "conditional-pull-request-review",
      repository: { owner: plan.owner, repo: plan.repo, number: plan.pr },
      event: "COMMENT",
      reviewedHead: plan.curHead,
      reviewedMergeBase: plan.newMergeBase,
      expectedBase: facts.pr.base,
      expectedHead: plan.curHead,
      observation: reviewObservation(facts, idempotencyMarker),
      payload: review.payload,
      limits: { maxComments: 0, maxBodyBytes: 262144 },
      dryRun: facts.request.dryRun,
      idempotencyKey: idempotencyMarker,
      preconditions: [
        { field: "state", operator: "equals", value: "open" },
        { field: "head", operator: "equals", value: plan.curHead },
        { field: "reviews", operator: "no-newer-own-review" },
        { field: "reviewBodies", operator: "not-contains", value: idempotencyMarker },
      ],
    };
  }

  function buildReviewedPost(facts, plan, snapshot, synthesis) {
    const counts = {
      confirmed: synthesis.summary.CONFIRMED,
      uncertain: synthesis.summary.UNCERTAIN,
      rejected: synthesis.summary.REJECTED,
    };
    const review = Post.constructReviewPayload({
      owner: plan.owner,
      repo: plan.repo,
      number: plan.pr,
      event: "COMMENT",
      commitId: plan.curHead,
      confirmed: synthesis.rows.filter((candidate) => candidate.status === "CONFIRMED"),
      counts,
      inputs: { head: plan.curHead, base: plan.newMergeBase },
      cost: costSummary(snapshot),
      roster: Post.candidateRoster(synthesis.rows),
      runSlug: facts.ownedResources.identity.runIdentity,
      anchorDiff: plan.anchorDiff,
      threeDotBase: plan.newMergeBase,
      postedAt: facts.execution.generatedAt,
      actions: {
        serverUrl: facts.request.serverUrl,
        repository: plan.repoSlug,
        runId: githubActionsRunId(facts.ownedResources.identity.runIdentity),
      },
    });
    const idempotencyMarker = Post.markerComment(review.marker);
    return {
      schemaVersion: 1,
      kind: "conditional-pull-request-review",
      repository: { owner: plan.owner, repo: plan.repo, number: plan.pr },
      event: "COMMENT",
      reviewedHead: plan.curHead,
      reviewedMergeBase: plan.newMergeBase,
      expectedBase: facts.pr.base,
      expectedHead: plan.curHead,
      observation: reviewObservation(facts, idempotencyMarker),
      payload: review.payload,
      limits: {
        maxComments: review.payload.comments?.length ?? 0,
        maxBodyBytes: 262144,
      },
      dryRun: facts.request.dryRun,
      idempotencyKey: idempotencyMarker,
      preconditions: [
        { field: "state", operator: "equals", value: "open" },
        { field: "head", operator: "equals", value: plan.curHead },
        { field: "reviews", operator: "no-newer-own-review" },
        { field: "reviewBodies", operator: "not-contains", value: idempotencyMarker },
      ],
    };
  }

  function buildHealthArtifact(plan, draft, snapshot) {
    const health = draft.health ?? {
      discovery: {
        attempts: [],
        selectedToolkitRoles: [],
        plannedAreaIds: [],
        retryAttempted: 0,
        retryRecovered: 0,
      },
      findings: {
        members: [
          { member: "claude-code--pr-review-toolkit", rawFindings: 0 },
          { member: "dynamic-review-areas", rawFindings: 0 },
        ],
        totalRawFindings: 0,
        candidates: 0,
        representedPoolIndexes: 0,
        candidateCoverageComplete: true,
      },
    };
    return {
      schemaVersion: 1,
      plannerMode: plan.mode,
      decisionStatus: draft.status,
      discovery: health.discovery,
      findings: health.findings,
      modelCalls: snapshot === null ? null : snapshot.callCount,
    };
  }

  async function finalizeDecision(facts, plan, draft) {
    // The OWS standard does not require every host to inject a settled usage
    // ledger. Do not turn that absence into made-up zero totals or call counts.
    const snapshot = typeof usage === "function" ? await usage() : null;
    const cost = Cost.renderCostReport({
      usage: snapshot,
      runIdentity: facts.ownedResources.identity.runIdentity,
      generatedAt: facts.execution.generatedAt,
      target: {
        changedFiles: facts.git.currentChangedFiles.length,
        prTitle: facts.pr.title,
      },
    });
    const post = draft.status === "advance"
      ? buildAdvancePost(facts, plan, snapshot)
      : draft.status === "reviewed"
        ? buildReviewedPost(facts, plan, snapshot, draft.synthesis)
        : null;
    const candidates = draft.candidates ?? emptyCandidates();
    const judgments = draft.judgments ?? {};
    const report = draft.report ?? draft.synthesis?.reportMarkdown
      ?? decisionReport(draft.status, draft.reason);
    const health = buildHealthArtifact(plan, draft, snapshot);
    const diff = plan.windowDiff ?? plan.anchorDiff ?? "";
    const artifactIdentity = {
      schemaVersion: 1,
      prUrl: plan.prUrl,
      strategy: facts.request.strategy,
      plannerMode: plan.mode,
      reviewedHead: plan.curHead,
      reviewedBase: facts.pr.base,
      reviewedMergeBase: plan.newMergeBase,
      syntheticBase: plan.baseT,
      promptBundleDigest: facts.promptBundle.bundleDigest,
      owsSourceDigest: facts.promptBundle.workflowDigest,
      gawRunIdentity: facts.ownedResources.identity.runIdentity,
      candidateCount: candidates.n_candidates ?? 0,
      judgmentCount: Object.keys(judgments).length,
    };
    const resultArtifact = {
      schemaVersion: 1,
      status: draft.status,
      reason: draft.reason,
      post,
      artifactIdentity,
      artifacts: {},
    };
    return {
      schemaVersion: 1,
      status: draft.status,
      reason: draft.reason,
      post,
      artifactIdentity,
      artifacts: {
        result: resultArtifact,
        candidates,
        judgments,
        report,
        cost,
        health,
        inputs: facts,
        diff,
      },
    };
  }

  async function run(value) {
    phase("Observe PR");
    const facts = parsedArgs(value);
    phase("Plan Review");
    const plan = Planner.planReview(facts);
    let draft;
    if (plan.mode === "refuse" || plan.mode === "skipped" || plan.mode === "noop") {
      draft = { status: plan.mode, reason: plan.reason };
    } else if (plan.mode === "advance") {
      draft = { status: "advance", reason: plan.reason };
    } else {
      draft = await Graph.runReviewGraph(facts, plan);
    }
    phase("Prepare Results");
    return finalizeDecision(facts, plan, draft);
  }

  return Object.freeze({ run });
})();

return await DeepGraph.run(args);
