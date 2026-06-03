class AiGeneration < ApplicationRecord
  # Audit trail of every AI call (prompt + raw model output) for review/debugging.
  validates :kind, presence: true
end
