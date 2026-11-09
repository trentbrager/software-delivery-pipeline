#!/bin/bash
# usage: ./verify.sh <stack> [status|approve|reject] [comment]

STACK=${1:-app-pipeline}
MODE=${2:-status}
COMMENT=${3:-"reviewed"}
OUT=verification-output.txt

run() {
  echo "\$ $*" | tee -a "$OUT"
  "$@" 2>&1 | tee -a "$OUT"
  echo | tee -a "$OUT"
}

out() {
  aws cloudformation describe-stacks --stack-name "$STACK" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}

PIPELINE=$(out PipelineName)
STAGE=$(out ApprovalStageName)
ACTION=$(out ApprovalActionName)
TOPIC=$(out ApprovalTopicArn)
ALB=$(out AlbUrl)

if [[ "$MODE" == "status" ]]; then
  run aws codepipeline get-pipeline --name "$PIPELINE" \
    --query "pipeline.stages[].{Stage:name,Provider:actions[0].actionTypeId.provider}" --output table
  run aws sns list-subscriptions-by-topic --topic-arn "$TOPIC" \
    --query "Subscriptions[].{Endpoint:Endpoint,Arn:SubscriptionArn}" --output table
  run aws codepipeline get-pipeline-state --name "$PIPELINE" \
    --query "stageStates[].{Stage:stageName,Status:latestExecution.status}" --output table
  run aws codepipeline list-pipeline-executions --pipeline-name "$PIPELINE" --max-items 5 \
    --query "pipelineExecutionSummaries[].{Id:pipelineExecutionId,Status:status,Commit:sourceRevisions[0].revisionId}" --output table
  run curl -s "$ALB/health"
  run curl -s "$ALB"
else
  STATUS=Approved; [[ "$MODE" == "reject" ]] && STATUS=Rejected
  TOKEN=$(aws codepipeline get-pipeline-state --name "$PIPELINE" \
    --query "stageStates[?stageName=='$STAGE'].actionStates[0].latestExecution.token" --output text)
  run aws codepipeline put-approval-result --pipeline-name "$PIPELINE" \
    --stage-name "$STAGE" --action-name "$ACTION" \
    --result "summary=$COMMENT,status=$STATUS" --token "$TOKEN"
fi
