require 'test_helper'

module Shipit
  class ReapDeadDeploymentsJobTest < ActiveSupport::TestCase
    setup do
      Task.where(status: Task::ACTIVE_STATUSES).update_all(status: 'success')

      @deploy = shipit_deploys(:shipit)
      @deploy.status = 'success'
      @deploy.save!

      @rollback = @deploy.build_rollback
      @rollback.status = 'running'
      @rollback.save!

      @zombie_deploy = shipit_deploys(:shipit2)
      @zombie_deploy.status = 'running'
      @zombie_deploy.save!
    end

    test 'reaps only zombie tasks' do
      refute_predicate @zombie_deploy, :error?

      Shipit::Deploy.any_instance.expects(:alive?).returns(false)
      Shipit::Rollback.any_instance.expects(:alive?).returns(true)
      ReapDeadDeploymentsJob.perform_now

      @zombie_deploy.reload
      assert_predicate @zombie_deploy, :error?

      @deploy.reload
      assert_predicate @deploy, :finished?

      @rollback.reload
      assert_predicate @rollback, :running?
    end
  end
end
