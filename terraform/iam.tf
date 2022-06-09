resource "google_project_iam_member" "iap-ssh" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "user:c2312f2685@bangkit.academy"
}