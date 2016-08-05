class AddColumnMakeToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :make, 				:string
    add_column :claims, :claim_type, 	:string
    add_column :claims, :model,			 	:string
    add_column :claims, :serial,		 	:string
    add_column :claims, :age,				 	:integer, :default => 0
    add_column :claims, :size,			 	:string
    add_column :claims, :condition,	 	:string
    add_column :claims, :estimate,	 	:string
    add_column :claims, :buyout,	 		:string
    add_column :claims, :reimbursement,	 	:string
    add_column :claims, :b_r_form,	 	:string
    add_column :claims, :service_call_fee,	 	:string
    add_column :claims, :work_order,	 	:string
    add_column :claims, :invoice_amount, :decimal, :precision => 10, :scale => 2
    add_column :claims, :notes, :text
    add_column :claims, :attach_url, :string
  end
end
